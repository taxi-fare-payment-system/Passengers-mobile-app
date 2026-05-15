# analytics_service — HTTP + Event interface

Base path: server root on `PORT` (default `8084`).

Default content type: JSON request/response with `Content-Type: application/json; charset=utf-8`, except CSV exports.

Authentication: JWT Bearer token via `Authorization: Bearer <token>`.

Authorization: RBAC enforced locally.
- `superadmin`: full system access; may optionally filter by `sub_city_id` query param.
- `admin`: restricted to gateway-injected `X-Sub-City` header.
- `driver`, `passenger`, `assistance`: `403 Forbidden`.

For `admin`, requests are rejected with `403` when `X-Sub-City` is missing or invalid.

---

## Environment variables used by the interface

- `PORT` (default `8084`)
- `RABBITMQ_URL` (preferred, e.g. `amqp://user:pass@rabbitmq:5672/`)
- `ANALYTICS_EXCHANGE` (default `analytics_exchange`)
- `RABBITMQ_QUEUE` (default `analytics.ingest`)
- `RABBITMQ_CONSUMER_TAG` (default `analytics_service`)
- `JWT_SECRET`

(`RABBITMQ_HOST`, `RABBITMQ_PORT`, `RABBITMQ_USER`, `RABBITMQ_PASSWORD` are still supported as fallback when `RABBITMQ_URL` is not set.)

---

## REST API endpoints

| Category | Method | Path | Description | Roles |
| :--- | :--- | :--- | :--- | :--- |
| Health | `GET` | `/api/v1/analytics/health` | Service health status | All |
| Users | `GET` | `/api/v1/analytics/users/counts` | Total users by role/status | `admin`, `superadmin` |
| Users | `GET` | `/api/v1/analytics/users/registrations` | User registration rates | `admin`, `superadmin` |
| Users | `GET` | `/api/v1/analytics/users/by-role` | User distribution by role | `admin`, `superadmin` |
| Users | `GET` | `/api/v1/analytics/users/by-status` | User distribution by status | `admin`, `superadmin` |
| Wallets | `GET` | `/api/v1/analytics/wallets/counts` | Wallet totals | `admin`, `superadmin` |
| Wallets | `GET` | `/api/v1/analytics/wallets/balance` | Wallet balances | `admin`, `superadmin` |
| Wallets | `GET` | `/api/v1/analytics/wallets/system-money` | Total funds in system | `admin`, `superadmin` |
| Money | `GET` | `/api/v1/analytics/movement/daily` | Money movement analytics | `admin`, `superadmin` |
| Money | `GET` | `/api/v1/analytics/movement/weekly` | Money movement analytics | `admin`, `superadmin` |
| Money | `GET` | `/api/v1/analytics/movement/monthly` | Money movement analytics | `admin`, `superadmin` |
| Money | `GET` | `/api/v1/analytics/movement/yearly` | Money movement analytics | `admin`, `superadmin` |
| Money | `GET` | `/api/v1/analytics/movement/summary` | Money movement summary | `admin`, `superadmin` |
| Vehicles | `GET` | `/api/v1/analytics/vehicles/counts` | Vehicle counts by approval state | `admin`, `superadmin` |
| Transactions | `GET` | `/api/v1/analytics/transactions/export` | Export transaction records as CSV | `admin`, `superadmin` |
| Dashboard | `GET` | `/api/v1/analytics/dashboard/overview` | Live KPI snapshot | `admin`, `superadmin` |

### Shared query parameters

Most analytics endpoints support:
- `start_date` (`YYYY-MM-DD`, default: 30 days ago)
- `end_date` (`YYYY-MM-DD`, default: today)
- `sub_city_id` (superadmin only)

Admin scoping source:
- `X-Sub-City`: required for `admin`; ignored for `superadmin`.

Period-aware endpoints also support:
- `period`: `daily` (default), `weekly`, `monthly`, `yearly`

### `GET /api/v1/analytics/vehicles/counts`

Query params:
- `period`, `start_date`, `end_date`, `sub_city_id` (superadmin only)

Success `200` example:
```json
[
  {
    "date": "2026-05-04T00:00:00Z",
    "approval_state": "APPROVED",
    "sub_city_id": 101,
    "total_vehicles": 42,
    "period": "daily"
  }
]
```

### `GET /api/v1/analytics/transactions/export`

Query params:
- `start_date`
- `end_date`
- `format` (only `csv` supported; default `csv`)
- `sub_city_id` (superadmin only)

Response:
- `200 OK`
- `Content-Type: text/csv`
- `Content-Disposition: attachment; filename=transactions.csv`

CSV columns:
- `transaction_id,amount,type,sub_city_id,date`

---

## RabbitMQ topology (canonical)

### Exchange declarations

| Exchange | Type | Durable | Auto-delete |
| :--- | :--- | :--- | :--- |
| `analytics_exchange` | `topic` | `true` | `false` |
| `notification.exchange` | `topic` | `true` | `false` |
| `document_events` | `topic` | `true` | `false` |
| `delivery.direct` | `direct` | `true` | `false` |

### Queue declaration (analytics consumer queue)

- Queue: `analytics.ingest`
- Durable: `true`
- Auto-delete: `false`
- Exclusive: `false`

Binding:
- Exchange: `analytics_exchange`
- Routing key: `analytics.#`

### Idempotency requirement

All events must carry an `id` field (`uuid-v4`). Duplicate events with the same `id` are ignored.

---

## Consumed events

Routing key pattern: `analytics.<domain>.<action>`

### User events
- `analytics.user.created`
- `analytics.user.status_updated`
- `analytics.user.banned`
- `analytics.user.unbanned`
- `analytics.user.deleted`
- `analytics.user.phone_verified`

Expected fields: `id`, `user_id`, `role`, `status`, `sub_city_id`

### Wallet events
- `analytics.wallet.created`
- `analytics.wallet.balance_updated`

Expected fields:
- `analytics.wallet.created`: `id`, `wallet_id`, `user_id`, `wallet_type`, `balance`
- `analytics.wallet.balance_updated`: `id`, `wallet_id`, `balance`, `delta`, `reason`, `sub_city_id` (nullable; fare events only)

### Transaction events
- `analytics.transaction.completed`

Expected fields: `id`, `transaction_id`, `sub_city_id`, `amount`, `type` or `reason`, `trip_id`, `date`

### Vehicle events
- `analytics.vehicle.created`
- `analytics.vehicle.approval_changed`
- `analytics.vehicle.driver_assigned`
- `analytics.vehicle.driver_unassigned`

Expected fields:
- `analytics.vehicle.created`: `id`, `vehicle_id`, `owner_id`
- `analytics.vehicle.approval_changed`: `id`, `vehicle_id`, `approval_state`, `reviewed_by`

### Other accepted analytics events

Currently accepted by the processor for compatibility and future KPIs:
- `analytics.trip.started`
- `analytics.trip.ended`
- `analytics.qr.issued`
- `analytics.qr.revoked`
- `analytics.document.uploaded`
- `analytics.document.status_updated`

---

## Response examples

### `GET /api/v1/analytics/dashboard/overview` success `200`
```json
{
  "total_users": 1500,
  "active_users": 1200,
  "total_wallets": 1450,
  "total_system_money": 250000.75,
  "today_transactions": 45,
  "today_volume": 1250.50
}
```

### Common error shape
```json
{ "error": "Detailed error message" }
```
