# QR Service Interface

This document describes **every HTTP endpoint** exposed by this service and the **data structures** (JSON) going in/out.

Base URL (local): `http://localhost:8089`

## Conventions

- **Content-Type**: send JSON bodies with `Content-Type: application/json`.
- **Trusted identity headers**:
  - Protected endpoints trust headers injected by the gateway.
  - `X-User-ID`: authenticated user or service account ID
  - `X-User-Role`: authenticated role
  - `X-Request-ID`: echoed on responses if provided; generated if absent
- **Path encoding**:
  - `:driver_id` is treated as a string path segment.
  - `:qrcode` **must be URL-encoded** when calling verify (it contains characters like `.`).
- **Error response envelope** (for non-2xx responses that return JSON):

```json
{ "error": "message" }
```

- **Authorization failures** return `403` with:

```json
{ "error": "forbidden" }
```

- **Verify endpoint** always responds `200` with `{ "valid": boolean }` for invalid/unknown codes (unless server misconfigured).

## Data structures

### `POST /api/v1/qr` request

```json
{
  "driver_id": "string"
}
```

### `DriverQRResponse` (used by POST/GET)

```json
{
  "driver_id": "string",
  "qr_code": "string"
}
```

The signed QR payload embedded inside `qr_code` includes at minimum:

```json
{
  "driver_id": "string",
  "issued_at": 1714930200
}
```

### `PUT /api/v1/qr/drivers/:driver_id` request

```json
{
  "driver_id": "string",
  "old_qr_code": "string",
  "new_qr_code": "string"
}
```

### `PutRotateResponse`

```json
{
  "driver_id": "string",
  "old_qr_code": "string",
  "new_qr_code": "string"
}
```

### `VerifyResponse`

```json
{
  "valid": true
}
```

## Endpoints

### `GET /api/v1/qr/healthz`

Operational health check.

- **Request body**: none
- **Responses**:
  - `200 OK`

```json
{ "ok": true }
```

---

### `POST /api/v1/qr`

Generate and store a new signed QR code for a driver.

- **Authorization**: `admin`, `superadmin` only
- **Headers**:
  - `X-User-ID` (required)
  - `X-User-Role` (required)
- **Request body**: `POST /api/v1/qr` request
- **Success response**:
  - `200 OK`: `DriverQRResponse`
- **Error responses**:
  - `400 Bad Request`: invalid JSON or missing/blank `driver_id`
  - `403 Forbidden`: caller is not allowed to generate QR codes
  - `409 Conflict`: driver already has an active QR code
  - `500 Internal Server Error`: DB not configured, secret not configured, or unexpected failure

On success, the service publishes an analytics event to RabbitMQ:
- Routing key: `analytics.qr.issued`
- Payload fields: `id`, `created_at`, `driver_id`

---

### `GET /api/v1/qr/drivers/:driver_id`

Fetch the currently-active QR code for a driver.

- **Authorization**:
  - the driver themselves (`X-User-ID == :driver_id`)
  - assigned assistant (`X-User-Role = driver-assistant` and Auth Service confirms assignment)
  - `admin`, `superadmin`
- **Headers**:
  - `X-User-ID` (required)
  - `X-User-Role` (required)
- **Request body**: none
- **Path params**:
  - `driver_id` (string, required)
- **Success response**:
  - `200 OK`: `DriverQRResponse`
- **Error responses**:
  - `400 Bad Request`: missing/blank `driver_id`
  - `403 Forbidden`: caller is not allowed to view this driver's QR
  - `404 Not Found`: no QR for driver
  - `500 Internal Server Error`: DB not configured, assistant authorization lookup failure, or unexpected failure

When the caller role is `driver-assistant`, QR Service validates the assignment through:

`GET {AUTH_SERVICE_BASE_URL}/api/v1/auth/drivers/:driverId/assistant`

---

### `DELETE /api/v1/qr/drivers/:driver_id`

Delete (revoke) the active QR code for a driver.

- **Authorization**: `admin`, `superadmin` only
- **Headers**:
  - `X-User-ID` (required)
  - `X-User-Role` (required)
- **Request body**: none
- **Path params**:
  - `driver_id` (string, required)
- **Success response**:
  - `204 No Content` (empty body)
- **Error responses**:
  - `400 Bad Request`: missing/blank `driver_id`
  - `403 Forbidden`: caller is not allowed to revoke QR codes
  - `404 Not Found`: no QR for driver
  - `500 Internal Server Error`: DB not configured or unexpected failure

On success, the service publishes an analytics event to RabbitMQ:
- Routing key: `analytics.qr.revoked`
- Payload fields: `id`, `created_at`, `driver_id`, `reason`
- Default `reason`: `"admin_revoke"`

---

### `PUT /api/v1/qr/drivers/:driver_id`

Rotate a driver’s active QR code.

Rotation rules enforced by the service:

- `driver_id` in the JSON body **must match** `:driver_id` in the URL.
- `old_qr_code` must be:
  - a valid signed QR (HMAC signature + optional expiration), and
  - belong to `driver_id` based on signed payload, and
  - match the currently stored active QR in the DB.
- `new_qr_code` must be:
  - a valid signed QR (HMAC signature + optional expiration), and
  - belong to `driver_id` based on signed payload.

- **Authorization**:
  - the driver themselves (`X-User-ID == :driver_id`)
  - `admin`, `superadmin`
- **Headers**:
  - `X-User-ID` (required)
  - `X-User-Role` (required)
- **Request body**: `PUT /api/v1/qr/drivers/:driver_id` request
- **Success response**:
  - `200 OK`: `PutRotateResponse`
- **Error responses**:
  - `400 Bad Request`: invalid JSON; missing fields; driver mismatch; invalid old/new QR code format/signature/expiration; QR belongs to a different driver
  - `403 Forbidden`: caller is not allowed to rotate this driver's QR
  - `409 Conflict`: old QR doesn’t match current active QR for driver; or DB uniqueness conflict during update
  - `500 Internal Server Error`: DB/secret not configured or unexpected failure

On success, the service publishes an analytics event to RabbitMQ:
- Routing key: `analytics.qr.rotated`
- Payload fields: `id`, `created_at`, `driver_id`

---

### `GET /api/v1/qr/:qrcode/verify`

Verify a QR code.

Verification logic:

1. Verify signature/structure using `HMAC_SECRET` (and optional expiration via `QR_EXPIRATION_SECONDS`).
2. Enforce revocation semantics: return `valid=true` **only if** the QR code currently exists in the DB.
   - If a QR was deleted or rotated out, it will no longer be present and will verify as invalid.

- **Authorization**:
  - any authenticated user may call this through the gateway
  - internal service-to-service callers may call it **without** identity headers
  - this endpoint does **not** enforce user-to-driver identity matching
- **Request body**: none
- **Path params**:
  - `qrcode` (string, required; must be URL-encoded)
- **Success responses**:
  - `200 OK`: `VerifyResponse` (`valid` is `true` or `false`)
- **Error responses**:
  - `500 Internal Server Error`: secret not configured; DB error during existence check

This endpoint is used by Trip Service, which should call:
- `GET /api/v1/qr/<url-encoded-qrcode>/verify`

and relay the response body:

```json
{ "valid": true }
```
