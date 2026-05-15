# Gateway Interface

## Purpose

This gateway is the single client entrypoint. It enforces authentication, role checks, traffic controls, and forwards requests to internal services.

## Identity And Headers

- JWT-protected routes require `Authorization: Bearer <token>`.
- JWT claims mapped by gateway:
  - `sub` -> `X-User-ID`
  - `role` -> `X-User-Role`
  - `sub_city_id` -> `X-Sub-City` (only when present)
- `X-Request-ID` is echoed if provided or generated as UUID and forwarded upstream.
- Auth is expected to emit `superadmin` in JWT; gateway forwards `role` as received.

### Header Trust Targets

For Document and Notification routes, gateway strips `Authorization` before proxying and injects trust headers (`X-User-ID`, `X-User-Role`, `X-Sub-City`, `X-Request-ID`).

Wallet routes also use the same identity header injection pattern; `X-Admin-User-Id` is not used.

## Public Routes

- `POST /api/v1/auth/register` -> Auth
- `POST /api/v1/auth/login` -> Auth
- `* /api/v1/auth/verify-phone` -> Auth
- `POST /api/v1/messaging/otp/*` -> Messaging
- `POST /webhooks/chapa` -> Payment `/webhooks/chapa` (no JWT)

## JWT-Protected Routes

- `/api/v1/auth/*` -> Auth
- `/api/v1/messaging/*` -> Messaging
- `/api/v1/routes/*` -> Route
- `/api/v1/trips/*` -> Trip
- `/api/v1/drivers/*/trips` -> Trip (rewritten to `/api/v1/trips?driver_id=<id>`)
- `/api/v1/wallet*` -> Wallet
- `/api/v1/qr/*` -> QR
- `/api/v1/documents/*` -> Document (header trust)
- `/api/v1/notifications/*` -> Notification (header trust)
- `/api/v1/analytics/*` -> Analytics
- `/api/v1/vehicles/*` -> Vehicle
- `/api/v1/drivers/*/vehicle` -> Vehicle (rewritten to `/api/v1/vehicles?driver_id=<id>`)
- `/api/v1/owners/*/vehicles` -> Vehicle (rewritten to `/api/v1/vehicles?owner_id=<id>`)

## Restricted Routes

- `/api/v1/payments/*` is blocked from public clients.
- `/internal/*` is never routed by gateway.
- `/v1/wallet/finalize-topup` and `/api/v1/wallet/finalize-topup` are restricted to `PAYMENT_IP_ALLOWLIST`.

## Role Enforcement

Gateway-level role checks return:

```json
{ "error": "forbidden", "message": "insufficient role" }
```

Protected sets:

- Route mutations:
  - `POST /api/v1/routes`
  - `PUT /api/v1/routes/:id`
  - `DELETE /api/v1/routes/:id`
  - `POST /api/v1/routes/:id/vehicles/:vid/assign`
  - `DELETE /api/v1/routes/:id/vehicles/:vid/assignment`
  - Required role: `admin` or `superadmin`
- QR mutations/reads:
  - `POST /api/v1/qr` -> `admin|superadmin`
  - `DELETE /api/v1/qr/drivers/:id` -> `admin|superadmin`
  - `PUT /api/v1/qr/drivers/:id` -> `driver|admin|superadmin`
  - `GET /api/v1/qr/drivers/:id` -> `driver|driver-assistant|admin|superadmin`
- Analytics:
  - `/api/v1/analytics/*` -> `admin|superadmin`
- Auth admin:
  - `/api/v1/auth/admin/*` -> `admin|superadmin`

## Error Contracts

- Invalid/expired JWT:

```json
{ "error": "unauthorized", "message": "invalid or expired token" }
```

- Upstream timeout:

```json
{ "error": "upstream_timeout", "traceId": "<X-Request-ID>" }
```

## Rate Limits

- `POST /api/v1/auth/login`: 10 req/min per IP
- `POST /api/v1/auth/register`: 5 req/min per IP
- `* /api/v1/auth/verify-phone`: 5 req/min per IP
- `POST /api/v1/messaging/otp/*`: 5 req/min per phone
- `POST /api/v1/trips/*/location`: 30 req/min per user
- `POST /api/v1/documents/upload`: 10 uploads/min per user
- All other JWT-protected routes: 60 req/min per user

## Body Size Limits

- `POST /api/v1/documents/upload`: 5 MB
- `POST /api/v1/auth/login`: 1 KB
- `POST /api/v1/auth/register`: 2 KB
- `POST /api/v1/messaging/otp/*`: 1 KB
- `POST /api/v1/trips/*/location`: 1 KB
- Default: 512 KB

## Timeouts

- Payment upstream timeout: 30s
- Document upstream timeout: 20s
- All other upstreams: 10s

## CORS

- Allowed origins from `CORS_ALLOWED_ORIGINS` (comma-separated; no wildcard with credentials).
- Allowed methods: `GET, POST, PUT, PATCH, DELETE, OPTIONS`
- Allowed headers: `Authorization, Content-Type, X-Request-ID`
- Exposed headers: `X-Request-ID`
- Credentials: enabled

## Security Notes

- HSTS header is set: `Strict-Transport-Security: max-age=31536000; includeSubDomains`.
- Chapa webhook can be restricted with `CHAPA_IP_ALLOWLIST` (comma-separated IPs).
- Internal service-to-service endpoints are not exposed through gateway routing.

## Required Environment

- `GATEWAY_PORT` (default `8000`)
- `READ_HEADER_TIMEOUT_SEC` (default `10`)
- `AUTH_JWT_SECRET` or `AUTH_JWKS_URL` (JWT verification currently uses `AUTH_JWT_SECRET`)
- `CORS_ALLOWED_ORIGINS` (comma-separated list)
- `CHAPA_IP_ALLOWLIST` (optional comma-separated list)
- `PAYMENT_IP_ALLOWLIST` (optional comma-separated list for wallet finalize-topup)
- Optional service URL overrides:
  - `GATEWAY_AUTH_URL`
  - `GATEWAY_TRIP_URL`
  - `GATEWAY_PAYMENT_URL`
  - `GATEWAY_QR_URL`
  - `GATEWAY_ANALYTICS_URL`
  - `GATEWAY_NOTIFICATION_URL`
  - `GATEWAY_ROUTE_URL`
  - `GATEWAY_VEHICLE_URL`
  - `GATEWAY_WALLET_URL`
  - `GATEWAY_DOCUMENT_URL`
  - `GATEWAY_MESSAGING_URL`
