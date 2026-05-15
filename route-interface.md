# Route Service Interface

This document describes **every HTTP endpoint** exposed by Route Service and the **data structures** (JSON) going in/out.

Base URL (local): `http://localhost:8081`

## Conventions

- **Content-Type**: send JSON bodies with `Content-Type: application/json`.
- **Authentication**:
  - `GET /api/v1/routes/healthz` is public.
  - All other endpoints require `Authorization: Bearer <jwt>`.
  - Route mutation endpoints require `admin` or `superadmin`.
- **Path params**:
  - `:id` is a route UUID.
  - `:vehicleId` is a vehicle identifier string.
- **Error response envelope** (non-2xx):

```json
{
  "traceId": "string",
  "code": "string",
  "message": "string"
}
```

Special case for route deletion conflicts:

```json
{
  "traceId": "string",
  "code": "ROUTE_DELETE_DEPENDENCY",
  "message": "active vehicle assignments exist",
  "vehicleIds": ["vehicle-1"]
}
```

## Data structures

### Point

```json
{
  "latitude": 8.84,
  "longitude": 38.79,
  "metadata": {
    "name": "Unisa"
  }
}
```

### Stop (coordinate payload on routes)

```json
{
  "latitude": 8.84,
  "longitude": 38.79,
  "metadata": {
    "name": "Unisa"
  }
}
```

### Stop catalog entry (`GET /api/v1/routes/stops...`)

Physical stops are shared across routes (many-to-many). Route-specific fields (sequence, role, metadata) live on the join table and are surfaced on route responses.

```json
{
  "id": "uuid",
  "sub_city_id": 101,
  "latitude": 8.84,
  "longitude": 38.79,
  "createdAt": "2026-04-21T00:00:00Z"
}
```

`sub_city_id` is set from the **first route** that registered the stop and is not updated later.

### `POST /api/v1/routes` request

```json
{
  "sub_city_id": 101,
  "start": {
    "latitude": 8.84731,
    "longitude": 38.79362,
    "metadata": { "name": "Unisa" }
  },
  "end": {
    "latitude": 8.7422,
    "longitude": 38.69075,
    "metadata": { "name": "Garment" }
  },
  "stops": [
    { "latitude": 8.84731, "longitude": 38.79362, "metadata": { "name": "Unisa" } },
    { "latitude": 8.81445, "longitude": 38.75672, "metadata": { "name": "Gelan" } }
  ]
}
```

**Alternative (create from existing stop IDs):** provide `start_stop_id`, `end_stop_id`, and `stop_ids` instead of coordinates. Start/end are still persisted on the route and registered in the join table with roles `START` / `END` / `WAYPOINT`.

```json
{
  "sub_city_id": 101,
  "start_stop_id": "uuid",
  "end_stop_id": "uuid",
  "stop_ids": ["uuid", "uuid"]
}
```

When using stop IDs, `start` / `end` / `stops` coordinate fields are optional. `start_stop_id` and `end_stop_id` are required in that mode; at least one waypoint is required via `stop_ids` or `stops`.

`sub_city_id` behavior:
- `admin`: Route Service reads `X-Sub-City` header; request-body `sub_city_id` is ignored.
- `superadmin`: `sub_city_id` is required in request body.

### `PUT /api/v1/routes/:id` request

Same shape as create (coordinates and/or stop IDs). `sub_city_id` is taken from the existing route.

```json
{
  "version": 1,
  "start": {
    "latitude": 8.84731,
    "longitude": 38.79362,
    "metadata": { "name": "Unisa" }
  },
  "end": {
    "latitude": 8.7422,
    "longitude": 38.69075,
    "metadata": { "name": "Garment" }
  },
  "stops": [
    { "latitude": 8.84731, "longitude": 38.79362, "metadata": { "name": "Unisa" } },
    { "latitude": 8.81445, "longitude": 38.75672, "metadata": { "name": "Gelan" } }
  ]
}
```

### Route response (`POST/GET/PUT /api/v1/routes...`)

```json
{
  "id": "uuid",
  "sub_city_id": 101,
  "start": {
    "latitude": 8.84731,
    "longitude": 38.79362,
    "metadata": { "name": "Unisa" }
  },
  "end": {
    "latitude": 8.7422,
    "longitude": 38.69075,
    "metadata": { "name": "Garment" }
  },
  "stops": [
    {
      "sequence": 0,
      "latitude": 8.84731,
      "longitude": 38.79362,
      "metadata": { "name": "Unisa" }
    }
  ],
  "stopCount": 1,
  "createdAt": "2026-04-21T00:00:00Z",
  "updatedAt": "2026-04-21T00:00:00Z",
  "version": 1
}
```

### `POST /api/v1/routes/vehicles/:vehicleId/track` request

```json
{
  "latitude": 8.81,
  "longitude": 38.75
}
```

## Endpoints

### `GET /api/v1/routes/healthz`

Operational health check.

- **Request body**: none
- **Response**:
  - `200 OK`

```json
{ "ok": true }
```

---

### `POST /api/v1/routes`

Create route with ordered stops.

- **Request body**: `POST /api/v1/routes` request
- **Success response**:
  - `201 Created`: route response
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid coordinates / insufficient stops / missing sub-city context
  - `401 Unauthorized`: missing/invalid JWT
  - `403 Forbidden`: role not allowed
  - `500 Internal Server Error`

---

### `GET /api/v1/routes`

List routes (paginated).

- **Query params**:
  - `page` (default `0`)
  - `pageSize` (default `20`)
  - `sub_city_id` (optional; `superadmin` filter)
  - `terminal_id` (optional; comma-separated terminal UUIDs — returns routes whose start/end pair matches any listed terminal, in either direction)
  - `include` (optional; comma-separated expansions)
    - `stops` — include waypoint `stops` and `stopCount` on each list item (same shape as route detail)
- **Scoping**:
  - `admin`: list is scoped to `X-Sub-City`.
  - `superadmin`: sees all routes unless `sub_city_id` is provided.
- **Success response**:
  - `200 OK`

```json
{
  "items": [
    {
      "id": "uuid",
      "sub_city_id": 101,
      "createdAt": "2026-04-21T00:00:00Z",
      "updatedAt": "2026-04-21T00:00:00Z",
      "version": 1,
      "startName": "Unisa",
      "endName": "Garment"
    }
  ],
  "pageInfo": {
    "page": 0,
    "pageSize": 20,
    "total": 1
  }
}
```

With `?include=stops`:

```json
{
  "items": [
    {
      "id": "uuid",
      "sub_city_id": 101,
      "createdAt": "2026-04-21T00:00:00Z",
      "updatedAt": "2026-04-21T00:00:00Z",
      "version": 1,
      "startName": "Unisa",
      "endName": "Garment",
      "stops": [
        {
          "sequence": 0,
          "latitude": 8.81445,
          "longitude": 38.75672,
          "metadata": { "name": "Gelan" }
        }
      ],
      "stopCount": 1
    }
  ],
  "pageInfo": {
    "page": 0,
    "pageSize": 20,
    "total": 1
  }
}
```

`startName` / `endName` are read from route-scoped stop metadata (`metadata.name` on the `START` / `END` join rows), falling back to the route’s denormalized start/end metadata when absent.

---

### `GET /api/v1/routes/:id`

Get route by ID.

- **Success response**:
  - `200 OK`: route response
- **Error responses**:
  - `400 Bad Request`: invalid route ID
  - `404 Not Found`
  - `401/403` auth failures

---

### `PUT /api/v1/routes/:id`

Update route geometry and ordered stops (full replacement semantics).

- **Request body**: `PUT /api/v1/routes/:id` request
- **Success response**:
  - `200 OK`: route response
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid coordinates / insufficient stops
  - `404 Not Found`
  - `403 Forbidden`: admin tried to modify route outside their sub-city
  - `409 Conflict`: optimistic version conflict
  - `401/403` auth failures

---

### `DELETE /api/v1/routes/:id`

Delete route.

- **Query params**:
  - `force=true|false` (default `false`)
- **Success response**:
  - `204 No Content`
- **Error responses**:
  - `400 Bad Request`: invalid route ID
  - `404 Not Found`
  - `403 Forbidden`: admin tried to modify route outside their sub-city
  - `409 Conflict`: active vehicle assignment exists (`ROUTE_DELETE_DEPENDENCY`)
  - `401/403` auth failures

---

### `POST /api/v1/routes/:id/vehicles/:vehicleId/assign`

Assign vehicle to route.

- **Request body**: none
- **Success response**:
  - `200 OK`

```json
{
  "id": "uuid",
  "routeId": "uuid",
  "vehicleId": "vehicle-1",
  "status": "ACTIVE",
  "assignedAt": "2026-04-21T00:00:00Z"
}
```

- **Error responses**:
  - `400 Bad Request`: invalid route ID / invalid input
  - `404 Not Found`: route or vehicle not found
  - `409 Conflict`: vehicle not approved/assignable or already actively assigned to different route
  - `401/403` auth failures

---

### `DELETE /api/v1/routes/:id/vehicles/:vehicleId/assignment`

Unassign active vehicle from route.

- **Request body**: none
- **Success response**:
  - `204 No Content`
- **Error responses**:
  - `400 Bad Request`: invalid route ID
  - `404 Not Found`: active assignment not found
  - `401/403` auth failures

---

### `GET /api/v1/routes/:id/vehicles`

Get active vehicle IDs for a route.

- **Success response**:
  - `200 OK`

```json
{
  "vehicleIds": ["vehicle-1"]
}
```

- **Error responses**:
  - `400 Bad Request`: invalid route ID
  - `401/403` auth failures

---

### `POST /api/v1/routes/vehicles/:vehicleId/track`

Update latest vehicle position (requires active assignment).

- **Request body**: `POST /api/v1/routes/vehicles/:vehicleId/track` request
- **Success response**:
  - `200 OK`

```json
{
  "vehicleId": "vehicle-1",
  "ok": true
}
```

- **Error responses**:
  - `400 Bad Request`: invalid JSON / coordinates
  - `401 Unauthorized`: missing/invalid JWT
  - `403 Forbidden`: caller is not the driver/assistant assigned to `:vehicleId` (validated via Vehicle Service)
  - `404 Not Found`: no active assignment for vehicle

---

### `GET /api/v1/routes/vehicles/:vehicleId/current-route`

Get active route assignment by vehicle.

- **Success response**:
  - `200 OK`

```json
{
  "routeId": "uuid",
  "vehicleId": "vehicle-1",
  "sub_city_id": 101,
  "assignedAt": "2026-04-21T00:00:00Z",
  "status": "ACTIVE"
}
```

- **Error responses**:
  - `404 Not Found`: no active assignment
  - `401/403` auth failures

---

### `GET /api/v1/routes/vehicles/by-subcity`

Get distinct active vehicle IDs currently assigned on routes within a given sub-city.

- **Query params**:
  - `sub_city_id` (required)
- **Success response**:
  - `200 OK`

```json
{
  "vehicle_ids": ["vehicle-uuid-1", "vehicle-uuid-2"]
}
```

- **Error responses**:
  - `400 Bad Request`: missing `sub_city_id`
  - `401/403` auth failures

---

## Route terminals (internal, read-only)

Route terminals are created automatically when a route is created. Each terminal represents a **canonical unordered pair** of start/end points: `Bole ↔ Piassa` and `Piassa ↔ Bole` resolve to the same record. Duplicate pairs are skipped silently. The `sub_city_id` is set from the **first route** that created the pair and is not updated on later routes.

Terminals cannot be created, updated, or deleted via the API.

### Route terminal response

```json
{
  "id": "uuid",
  "sub_city_id": 101,
  "terminalA": {
    "latitude": 8.7422,
    "longitude": 38.69075,
    "metadata": { "name": "Piassa" }
  },
  "terminalB": {
    "latitude": 8.84731,
    "longitude": 38.79362,
    "metadata": { "name": "Bole" }
  },
  "createdAt": "2026-04-21T00:00:00Z"
}
```

`terminalA` is always the lexicographically smaller `(latitude, longitude)` pair; `terminalB` is the larger.

---

### `GET /api/v1/routes/terminals`

List route terminals (paginated).

- **Query params**:
  - `page` (default `0`)
  - `pageSize` (default `20`)
  - `sub_city_id` (optional; `superadmin` filter)
- **Scoping**:
  - `admin`: list is scoped to `X-Sub-City`.
  - `superadmin`: sees all terminals unless `sub_city_id` is provided.
- **Success response**:
  - `200 OK`

```json
{
  "items": [
    {
      "id": "uuid",
      "sub_city_id": 101,
      "terminalA": { "latitude": 8.7422, "longitude": 38.69075, "metadata": { "name": "Piassa" } },
      "terminalB": { "latitude": 8.84731, "longitude": 38.79362, "metadata": { "name": "Bole" } },
      "createdAt": "2026-04-21T00:00:00Z"
    }
  ],
  "pageInfo": {
    "page": 0,
    "pageSize": 20,
    "total": 1
  }
}
```

---

### `GET /api/v1/routes/stops`

List shared stop catalog entries (paginated, filterable).

- **Query params**:
  - `page` (default `0`)
  - `pageSize` (default `20`)
  - `sub_city_id` (optional; `superadmin` filter)
  - `route_id` (optional; only stops linked to that route)
  - `min_lat`, `max_lat`, `min_lng`, `max_lng` (optional bounding box)
- **Scoping**:
  - `admin`: list is scoped to `X-Sub-City`.
  - `superadmin`: sees all stops unless `sub_city_id` is provided.
- **Success response**:
  - `200 OK`

```json
{
  "items": [
    {
      "id": "uuid",
      "sub_city_id": 101,
      "latitude": 8.84731,
      "longitude": 38.79362,
      "createdAt": "2026-04-21T00:00:00Z"
    }
  ],
  "pageInfo": {
    "page": 0,
    "pageSize": 20,
    "total": 1
  }
}
```

---

### `GET /api/v1/routes/stops/:id`

Get a stop catalog entry by ID.

- **Success response**:
  - `200 OK`: stop catalog entry
- **Error responses**:
  - `400 Bad Request`: invalid stop ID
  - `403 Forbidden`: admin tried to read stop outside their sub-city
  - `404 Not Found`
  - `401/403` auth failures

---

### `GET /api/v1/routes/terminals/:id/routes`

List routes for a single terminal (same response shape as `GET /api/v1/routes`).

- **Path params**:
  - `:id` — route terminal UUID
- **Query params**: same as `GET /api/v1/routes` (`page`, `pageSize`, `include`; `sub_city_id` for `superadmin` only)
- **Scoping**:
  - `admin`: terminal must belong to the caller’s `X-Sub-City`; listed routes are also scoped to that sub-city.
- **Success response**:
  - `200 OK`: paginated route list (see `GET /api/v1/routes`)
- **Error responses**:
  - `400 Bad Request`: invalid terminal ID
  - `403 Forbidden`: admin tried to read terminal outside their sub-city
  - `404 Not Found`: terminal not found
  - `401/403` auth failures

---

### `GET /api/v1/routes/terminals/:id`

Get a route terminal by ID.

- **Success response**:
  - `200 OK`: route terminal response
- **Error responses**:
  - `400 Bad Request`: invalid terminal ID
  - `403 Forbidden`: admin tried to read terminal outside their sub-city
  - `404 Not Found`
  - `401/403` auth failures
