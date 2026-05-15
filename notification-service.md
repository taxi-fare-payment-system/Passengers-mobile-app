# notification_service — HTTP + Event interface

Base path: server root on `PORT` (default `8090`).

Default content type: JSON request/response with `Content-Type: application/json; charset=utf-8`.

Correlation: response header `X-Request-ID` is always set (echoed if provided).

Timeout: on server-side deadline exceeded -> **504** with JSON `{"error":"request timeout"}`.

## Authentication model (Header Trust only)

The service does not validate JWTs and does not require `Authorization: Bearer ...`.

Gateway-injected headers:
- `X-User-ID` (required)
- `X-User-Role` (optional, defaults to `user`)
- `X-Sub-City` (optional; admin scope **sub-city id**, uint)

Sub-city ownership:
- Notification Service does not own sub-city entities.
- It reads `X-Sub-City` as a **uint sub-city id** for filtering only.
- Sub-city entity APIs are owned by Auth Service:
  - `GET http://auth:8082/api/v1/auth/subcities/:id`
  - `GET http://auth:8082/api/v1/auth/subcities`

If `X-User-ID` is missing on protected routes, response is:
```json
{ "error": "missing identity headers" }
```
with HTTP status **401**.

## Endpoints

### Health
- `GET /api/v1/notifications/health`

### User notification endpoints
- `GET /api/v1/notifications`
- `GET /api/v1/notifications/unread`
- `GET /api/v1/notifications/:id`
- `PUT /api/v1/notifications/:id/read`
- `PUT /api/v1/notifications/:id/unread`
- `PUT /api/v1/notifications/read-all`

### Admin endpoint
- `GET /api/v1/notifications/admin`

## REST API details

Base URL example: `http://notification-service:8090`

### `GET /api/v1/notifications`
Purpose: list paginated notifications for the authenticated user.

Query parameters:
- `status`: `read` or `unread` (optional)
- `limit`: default 20
- `offset`: default 0

Success `200`:
```json
{
  "items": [
    {
      "id": "<uuid>",
      "user_id": "user-123",
      "title": "Welcome",
      "content": "...",
      "status": "sent",
      "read_at": null,
      "created_at": "2026-05-05T12:00:00Z"
    }
  ],
  "total": 1,
  "unread_count": 1,
  "limit": 20,
  "offset": 0
}
```

### `GET /api/v1/notifications/unread`
Success `200`:
```json
{ "unread_count": 3 }
```

### `PUT /api/v1/notifications/:id/read`
Success `200`:
```json
{ "message": "Marked as read" }
```

### `PUT /api/v1/notifications/:id/unread`
Success `200`:
```json
{ "message": "Marked as unread" }
```

### `PUT /api/v1/notifications/read-all`
Success `200`:
```json
{ "message": "All notifications marked as read" }
```

### `GET /api/v1/notifications/admin`
Requires `X-User-Role: admin`.

Uses `X-Sub-City` (uint) as scope filter.

Success `200`:
```json
{
  "items": [],
  "total": 0
}
```

Common error body:
```json
{ "error": "Detailed error message" }
```

## RabbitMQ topology

### Incoming exchanges (consumed)

1) `notification.exchange` (topic)
- Queue: `notification.commands`
- Binding key: `notification.#`

2) `document_events` (topic)
- Queue: `notification.document`
- Binding key: `document.status.*`

## Incoming event contracts

### A) Generic notifications via `notification.exchange`
Routing key example: `notification.wallet.topup_succeeded`

Payload:
```json
{
  "event_id": "uuid-v4",
  "user_id": "user-uuid",
  "user_role": "passenger",
  "type": "payment_success",
  "title": "Payment Received",
  "content": "You have successfully paid 50 ETB.",
  "priority": "normal",
  "category": "billing",
  "channels": ["sms", "email"],
  "metadata": {
    "phone": "+251911223344",
    "email": "user@example.com"
  }
}
```

Behavior:
- idempotency on `event_id`
- persists in-app notification
- dispatches to `delivery.direct` for `sms` and/or `email`
- if dispatch cannot complete (for example missing contact), status is set to `pending_dispatch` and message is retried

Special case (`notification.wallet.pay_fare_succeeded`):
- if `metadata.assistant_id` is present, a second notification is created for the assistant user
- assistant channels are constrained to `push`/`sms`; if unavailable, default is `push`

### B) Document status events via `document_events`
Routing key example: `document.status.updated`

Payload:
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

Behavior:
- persists in-app notification
- approved: title `Document Approved`, content `Your {document_type} has been verified.`
- rejected: title `Document Rejected`, content `Your {document_type} was rejected: {rejection_reason}. Please re-upload.`
- resolves contact info from Auth internal endpoint:
  - `GET http://auth:8082/internal/users/:user_id/contact`
- if contact resolution or dispatch fails, notification is stored with `pending_dispatch` and the message is retried

## Outgoing delivery events (internal dispatch)

Exchange: `delivery.direct` (direct)

> Push dispatch is intentionally omitted until a push worker is available.

| Routing key | Payload |
|---|---|
| `delivery.sms` | `{"to":"+251...","message":"...","metadata":{"notification_id":"...","user_id":"..."}}` |
| `delivery.email` | `{"to":"user@example.com","subject":"...","body":"...","metadata":{"notification_id":"...","user_id":"..."}}` |

## Environment variables

```env
PORT=8090
RABBITMQ_URL=amqp://user:pass@rabbitmq:5672/
NOTIFICATION_EXCHANGE=notification.exchange
RABBITMQ_QUEUE=notification.commands
DOCUMENT_EVENTS_EXCHANGE=document_events
DOCUMENT_EVENTS_QUEUE=notification.document
DELIVERY_EXCHANGE=delivery.direct
AUTH_SERVICE_BASE_URL=http://auth:8082
```
