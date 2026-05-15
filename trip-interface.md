# Trip Service Interface

Base URL (local): `http://localhost:8086`

## Conventions

- `GET /api/v1/trips/healthz` is public.
- All other endpoints require `Authorization: Bearer <jwt>`.
- Error envelope:

```json
{
  "traceId": "string",
  "code": "string",
  "message": "string"
}
```

## Data structures

### `POST /api/v1/trips` request

```json
{
  "routeId": "uuid",
  "driverId": "driver-1",
  "startStopIndex": 0,
  "endStopIndex": 12
}
```

- `startStopIndex` (**required**): first stop on this trip segment — sent by the driver app; not inferred by the server.
- `endStopIndex` (**required**): last stop on this trip segment — sent by the driver app; not inferred by the server.
- Session `currentStopIndex` is initialized to `startStopIndex` at create; thereafter the driver app updates it via `POST /api/v1/trips/:id/location` together with live GPS.

### Trip response

```json
{
  "id": "uuid",
  "driverId": "driver-1",
  "routeId": "uuid",
  "startStopIndex": 0,
  "endStopIndex": 12,
  "status": "ACTIVE",
  "startedAt": "2026-04-21T00:00:00Z",
  "endedAt": null,
  "session": {
    "currentLat": 8.81445,
    "currentLng": 38.75672,
    "currentStopIndex": 2,
    "updatedAt": "2026-04-21T00:45:00Z"
  }
}
```

### `POST /api/v1/trips/:id/quotes/price` response

```json
{
  "amount": 63.45,
  "distanceKm": 4.23,
  "ratePerKm": 15.0,
  "destinationStopIndex": 4
}
```

### `POST /api/v1/trips/:id/payments/initiate` request

```json
{
  "amount": 123.45,
  "wallet_id": "passenger-wallet-uuid",
  "driver_id": "123",
  "message": "optional note"
}
```

### `POST /api/v1/trips/:id/payments/initiate` response

```json
{
  "transactionId": "uuid",
  "txRef": "pay-uuid",
  "receiptUrl": "https://..."
}
```

## Endpoints

### `GET /api/v1/trips/healthz`

- `200 OK`

### `POST /api/v1/trips`

- Creates an active trip session for a driver on a route.
- Allowed roles for setting `driverId` to another driver: `admin`, `driver-assistant`. A `driver` can only omit `driverId` (defaults to self).
- Validation chain before create:
  - driver has assigned vehicle (Vehicle Service)
  - selected route’s `terminal_id` matches the vehicle’s assigned terminal (Route Service `current-terminal` + route detail)
  - persists `sub_city_id` from the selected route onto the trip row
- Errors:
  - `409 NO_VEHICLE_ASSIGNED`
  - `409 VEHICLE_NOT_ON_ROUTE` — selected route is not on the vehicle’s assigned terminal
  - `502 ROUTE_UNAVAILABLE|VEHICLE_UNAVAILABLE`

### `GET /api/v1/trips/:id`

- Fetch single trip (optional `status=ACTIVE|ENDED|ALL`).

### `GET /api/v1/trips/drivers/:driverId`

- List trips by driver with pagination.
- Allowed roles: `driver` (own trips only), `admin`, `driver-assistant`.

### `GET /api/v1/trips/drivers/:driverId/active`

- Returns the single `ACTIVE` trip for a driver.
- `404` if no active trip.

### `PUT /api/v1/trips/:id/status`

- Supports transition to `ENDED`.
- Allowed roles: `driver` (own trips only), `admin`, `driver-assistant`.
- Publishes `analytics.trip.ended` event.

### `POST /api/v1/trips/:id/location`

- Updates GPS and current stop index.
- `currentStopIndex` must progress toward `endStopIndex` (increase when forward, decrease when backward) and stay within `[startStopIndex, endStopIndex]` along the trip direction.
- Allowed roles:
  - `driver` for own trip
  - `driver-assistant` only if assigned to trip driver via Auth Service
- `502` when Auth/Route service is unavailable.

### `GET /api/v1/trips/:id/stops/next`

- Lists upcoming stops from the vehicle’s current position toward `endStopIndex`, with per-stop road distance and fare.
- Direction is inferred from `startStopIndex` vs `endStopIndex`:
  - `startStopIndex <= endStopIndex` → `forward` (ascending stop indices)
  - `startStopIndex > endStopIndex` → `backward` (descending stop indices)
- Next stops are those strictly ahead of `session.currentStopIndex` along that direction, capped at `endStopIndex`.
- `distanceKm` per stop uses OpenRouteService driving distance from current GPS to the stop; `amount = distanceKm * ratePerKm`.

**Response 200:**

```json
{
  "direction": "forward",
  "currentStopIndex": 2,
  "startStopIndex": 0,
  "endStopIndex": 12,
  "stops": [
    {
      "stopIndex": 3,
      "latitude": 8.82,
      "longitude": 38.76,
      "distanceKm": 1.4,
      "ratePerKm": 15.0,
      "amount": 21.0
    }
  ]
}
```

### `POST /api/v1/trips/:id/quotes/price`

- Computes suggested fare as:
  - `amount = distanceKm * ratePerKm`
- `destinationStopIndex` must be one of the upcoming stops returned by `GET /api/v1/trips/:id/stops/next` (same direction/range rules).
- `distanceKm` is road distance from current trip position to destination stop, via OpenRouteService Matrix API (`POST /v2/matrix/driving-car`, profile `driving-car`, metric `distance`, units `km`).
- `ratePerKm` comes from Vehicle Service tariff (`vehicleType.pricePerKm`).
- No base fare and no hardcoded fallback.
- `502 ROUTING_UNAVAILABLE` when OpenRouteService is unreachable or no route exists.

### `POST /api/v1/trips/:id/payments/initiate`

- Client-facing payment facade.
- Accepted client payload fields only: `amount`, `wallet_id`, `driver_id`, optional `message`.
- Allowed roles: `passenger`, `admin`, `superadmin`.
- Trip Service calls Wallet `PUT /api/v1/wallet/:wallet_id/pay-fare` internally.
- Trip Service resolves driver wallet via Wallet `GET /api/v1/wallet/users/:driverId?type=driver` using JWT identity headers.
- Rejects requests when path trip driver and payload `driver_id` do not match.
- Includes optional `assistant_id` (resolved from Auth Service) and `sub_city_id` (uint) from trip context.

### `POST /api/v1/trips/integrations/qr/verify`

- Proxies QR verification to QR Service.

## Outbound integrations

- Auth Service: `GET /api/v1/auth/drivers/:driverId/assistant`
- Vehicle Service: `GET /api/v1/vehicles/drivers/:driverId/vehicle`
- Vehicle Service: `GET /api/v1/vehicles/vehicle-types/:vehicleTypeId`
- Route Service: `GET /api/v1/routes/:routeId`
- Route Service: `GET /api/v1/routes/vehicles/:vehicleId/route`
- Wallet Service: `PUT /api/v1/wallet/:wallet_id/pay-fare`
- Wallet Service: `GET /api/v1/wallet/users/:driverId?type=driver`
- QR Service: `GET /api/v1/qr/:urlEncodedQrCode/verify`
- OpenRouteService: `POST /v2/matrix/driving-car` (road distance for fare quotes; requires `OPENROUTESERVICE_API_KEY`)
