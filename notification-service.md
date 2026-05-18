# notification_service — HTTP + Event interface

Base URL: `http://<host>:<PORT>` (default `PORT=8090`).

Default content type: JSON request/response with `Content-Type: application/json; charset=utf-8`.

Correlation: every response includes `X-Request-ID` (echoed from the request header when provided, otherwise generated).

Request timeout: **15s** server-side deadline. On expiry → **504** with:

```json
{ "error": "request timeout" }
```

## Authentication model (Header Trust only)

The service does **not** validate JWTs and does **not** require `Authorization: Bearer ...`. The API gateway validates identity and injects headers.

| Header | Required | Description |
|--------|----------|-------------|
| `X-User-ID` | Yes (protected routes) | User identifier (opaque string, e.g. UUID) |
| `X-User-Role` | No | Role string; defaults to `user` when omitted |
| `X-Sub-City` | No | Admin scope: **uint sub-city id** (numeric string, e.g. `1`) |

### Header errors

| Condition | Status | Body |
|-----------|--------|------|
| Missing `X-User-ID` on a protected route | **401** | `{ "error": "missing identity headers" }` |
| Invalid `X-Sub-City` (non-numeric) | **400** | `{ "error": "invalid X-Sub-City header (expected uint id)" }` |
| Admin route without `admin` role | **403** | `{ "error": "Admin access required" }` |

Sub-city ownership: this service does **not** own sub-city entities. It only filters admin results using `X-Sub-City`. Sub-city CRUD lives in Auth Service (`GET /api/v1/auth/subcities`, etc.).

## HTTP endpoints

### Public

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/notifications/health` | No | Liveness check |
| `GET` | `/notifications/stream` | No | SSE stream (see below) |

### Authenticated (`AuthMiddleware`)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/notifications` | List notifications for `X-User-ID` |
| `GET` | `/api/v1/notifications/unread` | Unread count |
| `GET` | `/api/v1/notifications/:id` | Get one notification by UUID |
| `PUT` | `/api/v1/notifications/:id/read` | Mark one as read |
| `PUT` | `/api/v1/notifications/:id/unread` | Mark one as unread |
| `PUT` | `/api/v1/notifications/read-all` | Mark all unread as read for user |
| `POST` | `/api/v1/notifications/register` | Register FCM/push device token |

### Admin (`AuthMiddleware` + `AdminOnly`)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/notifications/admin` | List notifications scoped to `X-Sub-City` |

> **Route order:** Gin registers `/unread` and `/admin` before `/:id`, so those paths are not captured as IDs.

### Common error body

```json
{ "error": "<message>" }
```

Typical status codes: **400** (bad request), **401** (unauthorized), **403** (forbidden), **404** (not found), **500** (internal).

---

## REST API details

### `GET /api/v1/notifications/health`

**200**

```json
{
  "status": "up",
  "service": "notification-service"
}
```

### `GET /api/v1/notifications`

Query parameters:

| Param | Default | Values |
|-------|---------|--------|
| `status` | _(empty = all)_ | `read`, `unread` |
| `limit` | `20` | integer |
| `offset` | `0` | integer |

**200**

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "d924a873-a00b-4479-a73d-fe8d9875021f",
      "user_role": "passenger",
      "type": "topup_success",
      "title": "Payment Received",
      "content": "You have successfully paid 50 ETB.",
      "priority": "normal",
      "category": "billing",
      "channels": ["sms"],
      "status": "sent",
      "read_at": null,
      "event_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "metadata": { "sub_city_id": "1" },
      "created_at": "2026-05-15T12:00:00Z",
      "updated_at": "2026-05-15T12:00:00Z"
    }
  ],
  "total": 1,
  "unread_count": 1,
  "limit": 20,
  "offset": 0
}
```

Unread is determined by `read_at IS NULL`, not only by `status`.

### `GET /api/v1/notifications/unread`

**200**

```json
{ "unread_count": 3 }
```

### `GET /api/v1/notifications/:id`

Returns the full notification object (same fields as list items). Does not verify that the notification belongs to `X-User-ID`.

### `PUT /api/v1/notifications/:id/read`

Sets `read_at` and `status: "read"`.

**200**

```json
{ "message": "Marked as read" }
```

### `PUT /api/v1/notifications/:id/unread`

Clears `read_at` and sets `status: "sent"`.

**200**

```json
{ "message": "Marked as unread" }
```

### `PUT /api/v1/notifications/read-all`

Marks all notifications with `read_at IS NULL` for `X-User-ID` as read.

**200**

```json
{ "message": "All notifications marked as read" }
```

### `POST /api/v1/notifications/register`

Registers a device token for push delivery.

**Request body**

```json
{
  "token": "fcm-device-token",
  "platform": "android"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `token` | Yes | FCM / push token |
| `platform` | No | Defaults to `android` (`ios`, `android`, `web` expected) |

**200**

```json
{ "message": "Token registered successfully" }
```

### `GET /api/v1/notifications/admin`

Requires `X-User-Role: admin` and `X-Sub-City` (uint id).

Filters notifications where `metadata.sub_city_id` **or** legacy `metadata.sub_city` equals the header value (string match on numeric id).

Query: `limit` (default `20`), `offset` (default `0`).

**200**

```json
{
  "items": [],
  "total": 0
}
```

**400** if `X-Sub-City` was not provided (no `sub_city_id` in request context):

```json
{ "error": "Sub-city scope not found in session" }
```

### `GET /notifications/stream`

Server-Sent Events endpoint. **No header-trust middleware** — passes `user_id` as a query parameter.

Query: `user_id` (required).

Headers: `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`.

Behavior today: emits an SSE `heartbeat` event every **5 seconds** (`data: keep-alive`). Does not yet push real notification payloads.

**400** if `user_id` query param is missing.

---

## Notification statuses

| Status | Meaning |
|--------|---------|
| `sent` | Stored; dispatch succeeded or not applicable (e.g. push-only with no tokens) |
| `read` | User marked read (`read_at` set) |
| `pending_dispatch` | At least one channel failed; RabbitMQ message will be retried |
| `dispatch_failed` | Dispatch abandoned (permanent error or max retries exceeded) |

Internal metadata key `dispatch_attempts` tracks retry count (string integer).

---

## RabbitMQ — consumed (incoming)

### 1) `notification.exchange` (topic)

| Setting | Default env | Value |
|---------|-------------|-------|
| Exchange | `NOTIFICATION_EXCHANGE` | `notification.exchange` |
| Queue | `RABBITMQ_QUEUE` | `notification.commands` |
| Binding | — | `notification.#` |

**Routing key example:** `notification.wallet.topup_succeeded`

**Payload (`NotificationEvent`)**

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "d924a873-a00b-4479-a73d-fe8d9875021f",
  "user_role": "passenger",
  "type": "topup_success",
  "title": "Payment Received",
  "content": "You have successfully paid 50 ETB.",
  "priority": "normal",
  "category": "billing",
  "channels": ["sms", "email", "push"],
  "metadata": {
    "phone": "+251911223344",
    "email": "user@example.com",
    "sub_city_id": "1",
    "assistant_id": "assistant-user-id"
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `event_id` | Recommended | UUID v4; idempotency key. If omitted, a **deterministic UUID** is derived from `routingKey + body` |
| `user_id` | Yes | String or JSON number (stored as string) |
| `user_role` | No | |
| `type` | No | Event type label (e.g. `topup_success`, `wallet.pay_fare_succeeded`) |
| `title`, `content` | No | |
| `priority` | No | Default `normal` (`low`, `normal`, `high`, `urgent`) |
| `category` | No | e.g. `trip`, `payment`, `wallet`, `billing`, `account` |
| `channels` | No | `sms`, `email`, `push` (case-insensitive) |
| `metadata` | No | String map; channel-specific keys below |

**Channel requirements**

| Channel | Required data | Lookup fallback |
|---------|---------------|-----------------|
| `sms` | `metadata.phone` | `GET {AUTH_SERVICE_URL}/api/v1/auth/internal/users/{user_id}` → `data.phone` |
| `email` | `metadata.email` | — |
| `push` | Device token(s) in DB | Registered via `POST /api/v1/notifications/register` |

**Processing behavior**

1. Idempotent on `event_id` (skip if already processed and not `pending_dispatch`).
2. Persist notification, then dispatch per `channels`.
3. On transient dispatch failure → `pending_dispatch`, increment `metadata.dispatch_attempts`, return error → message **requeued** (max **10** consumer redeliveries, then dropped).
4. On **permanent** failure (`missing phone metadata`, `missing email metadata`) → `dispatch_failed` immediately, message **acked** (no retry).
5. After **10** dispatch attempts → `dispatch_failed`, message **acked**.

**Assistant fan-out** (types `pay_fare_succeeded` or `wallet.pay_fare_succeeded`):

If `metadata.assistant_id` is set, a second notification is created for that user with a new `event_id`, `user_role: "assistant"`, and channels from `metadata.assistant_channels` (comma-separated `push`/`sms`; default `["push"]`).

### 2) `document_events` (topic)

| Setting | Default env | Value |
|---------|-------------|-------|
| Exchange | `DOCUMENT_EVENTS_EXCHANGE` | `document_events` |
| Queue | `DOCUMENT_EVENTS_QUEUE` | `notification.document` |
| Binding | — | `document.status.*` |

**Routing key example:** `document.status.updated`

**Payload**

```json
{
  "event": "document.status.updated",
  "document": {
    "id": "doc-uuid",
    "user_id": "driver-123",
    "document_type": "national_id",
    "status": "approved",
    "verified_by": "admin-456",
    "verified_at": "2026-05-04T11:00:00Z",
    "rejection_reason": null
  }
}
```

**Behavior**

- Builds in-app notification with `type: "document.status.updated"`, `category: "account"`.
- **Approved:** title `Document Approved`, content `Your {document_type} has been verified.`
- **Rejected:** title `Document Rejected`, content includes `rejection_reason` (default `No reason provided`).
- Resolves SMS/email via Auth contact endpoint (see below), then same dispatch/retry rules as generic events.
- `event_id` is generated as a new UUID per document event (not derived from the document id).

---

## RabbitMQ — published (outgoing delivery)

Exchange: `delivery.direct` (direct), env `DELIVERY_EXCHANGE` (default `delivery.direct`).

| Routing key | Payload |
|-------------|---------|
| `delivery.sms` | `{ "to": "+251...", "message": "...", "metadata": { "notification_id": "<uuid>", "user_id": "<user_id>" } }` |
| `delivery.email` | `{ "to": "user@example.com", "subject": "...", "body": "...", "metadata": { "notification_id": "<uuid>", "user_id": "<user_id>" } }` |
| `delivery.push` | `{ "token": "<device_token>", "title": "...", "body": "..." }` |

Messages are persistent JSON (`Content-Type: application/json`).

---

## Upstream Auth Service integrations

Two separate base URLs are used:

| Purpose | Env var(s) | Default | Endpoint |
|---------|------------|---------|----------|
| Contact lookup (document events) | `SERVICE_AUTH_URL` or `AUTH_SERVICE_BASE_URL` | `http://auth:8082` | `GET /internal/users/:user_id/contact` → `{ "phone", "email" }` |
| SMS phone fallback | `AUTH_SERVICE_URL` | `http://auth-service:8088` | `GET /api/v1/auth/internal/users/:user_id` → `{ "status", "message", "data": { "id", "phone", "role" } }` |

---

## Environment variables

```env
# Server
PORT=8090
ENVIRONMENT=development

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=notification_db
DB_SSL_MODE=disable

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
NOTIFICATION_EXCHANGE=notification.exchange
RABBITMQ_QUEUE=notification.commands
DOCUMENT_EVENTS_EXCHANGE=document_events
DOCUMENT_EVENTS_QUEUE=notification.document
DELIVERY_EXCHANGE=delivery.direct
RABBITMQ_CONSUMER_TAG=notification-consumer

# Auth integrations
AUTH_SERVICE_BASE_URL=http://auth:8082
SERVICE_AUTH_URL=http://auth:8082
AUTH_SERVICE_URL=http://auth-service:8088
```

`RABBITMQ_URL` takes precedence over host/user/password when set. `SERVICE_AUTH_URL` overrides `AUTH_SERVICE_BASE_URL` for contact resolution when both are set.
