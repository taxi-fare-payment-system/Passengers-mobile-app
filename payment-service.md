# payment_service — HTTP interface (endpoints + schemas)

Base path: server root on `PORT` (default `8080`).

Default content type: JSON request/response with `Content-Type: application/json; charset=utf-8` unless noted.

Correlation: response header `X-Request-ID` is always set (echoed if provided).

Timeout: on server-side deadline exceeded → **504** with JSON `{"message":"request timeout"}`.

Authentication: no API key/JWT validation in handlers (protect at edge).

## Endpoints

### Health

- `GET /api/v1/payments/health`
- `GET /api/v1/payments/healthz`

### Payments

- `POST /api/v1/payments/initiate`

### Transactions

- `GET /api/v1/payments/transactions`
- `GET /api/v1/payments/transactions/:id`

### Receipts

- `GET /api/v1/payments/receipts/:id`

### Dedicated internal + Chapa refund routes

- `POST /api/v1/payments/transfers`
- `POST /api/v1/payments/withdrawals`
- `GET /api/v1/payments/banks/chapa`
- `POST /api/v1/payments/refunds`
- `POST /api/v1/payments/refunds/topup`

### Webhooks (incoming)

- `POST {CHAPA_WEBHOOK_PATH}` (default: `/api/v1/payments/webhooks/chapa`)

## Common response error shape (JSON)

Most non-HTML errors return:

```json
{ "message": "..." }
```

## Schemas by endpoint

### `GET /api/v1/payments/health` and `GET /api/v1/payments/healthz`

**Response 200 (JSON):**

```json
{
  "status": "ok",
  "service": "payment_service",
  "timestamp": "2025-03-22T12:00:00.000000000Z"
}
```

`timestamp` is RFC3339Nano UTC.

---

### `POST /api/v1/payments/initiate`

Purpose: create a transaction and either start **Chapa** checkout (`wallet topup`) or record an **internal** payment (`fare`/`refund`) through this flow.

**Request body (JSON):**

```json
{
  "amount": 1.23,
  "reason": "wallet topup",
  "payer_user_id": "user-123",
  "receiver_id": "user-456",
  "sender_wallet_id": "wallet-1",
  "receiver_wallet_id": "wallet-2",
  "receiver_full_name": "Receiver Name",
  "trip_id": "trip-uuid",
  "message": "optional note",
  "phone_number": "+251900000000",
  "email": "user@example.com",
  "payer_phone": "+251900000000",
  "payer_email": "user@example.com",
  "first_name": "First",
  "last_name": "Last"
}
```

**Validation highlights (from API doc):**

- `reason = withdraw` is not accepted on this endpoint; use `POST /api/v1/payments/withdrawals`.
- `reason = transfer` and `reason = refund_topup` are **not supported here** → **400** and must use dedicated routes.
- `wallet topup`: `receiver_id` must be empty; `sender_wallet_id`, `first_name`, `last_name` required; `PUBLIC_BASE_URL` and `CHAPA_SECRET_KEY` required (else **503**).
- `fare` / `refund`: `receiver_id`, `sender_wallet_id`, `receiver_wallet_id`, `trip_id` required.
- `wallet topup`: `trip_id` must be empty/not sent.
- `phone_number` is required for `wallet topup`.
- `payer_phone` and `payer_email` are optional; when provided they are stored and may be forwarded in notification metadata.

**Success 200 (wallet topup) (JSON):**

```json
{
  "transaction_id": "<uuid>",
  "checkout_url": "<Chapa hosted checkout URL>"
}
```

**Success 200 (fare/refund initiate path) (JSON):**

```json
{
  "transaction_id": "<uuid>",
  "tx_ref": "pay-<uuid>"
}
```

**Common errors:**

- **400** invalid JSON/binding/validation message
- **503** missing config for wallet topup
- **502** Chapa initialize failure
- **500** server/persistence error

---

### `GET /api/v1/payments/transactions`

Purpose: list transactions with optional filters and sorting.

**Query parameters:**

- `payer_user_id` (exact match)
- `trip_id` (exact match)
- `reason` (exact match)
- `status` (exact match)
- `assistant_id` (exact match)
- `sender_wallet_id` (exact match)
- `receiver_wallet_id` (exact match)
- `sort` = `created_at` (default) or `amount`
- `order` = `desc` (default) or `asc`
- `limit` default 50, max 200
- `offset` default 0, non-negative

**Response 200 (JSON):**

```json
{
  "items": [
    {
      "id": "<uuid>",
      "amount": "1.2300",
      "reason": "fare",
      "payer_user_id": "user-123",
      "receiver_id": "user-456",
      "sender_wallet_id": "wallet-1",
      "receiver_wallet_id": "wallet-2",
      "receiver_full_name": "Receiver Name",
      "parent_transaction_id": null,
      "trip_id": "trip-uuid",
      "assistant_id": "assistant-uuid-or-null",
      "sub_city_id": 123,
      "message": null,
      "status": "succeeded",
      "tx_ref": "pay-<uuid>",
      "chapa_reference": null,
      "receipt_url": null,
      "created_at": "2025-03-22T12:00:00.000000000Z",
      "updated_at": "2025-03-22T12:00:00.000000000Z"
    }
  ],
  "limit": 50,
  "offset": 0,
  "sort": "created_at",
  "order": "desc"
}
```

Errors: **400** invalid `sort|order|limit|offset`; **500** database error.

---

### `GET /api/v1/payments/transactions/:id`

Purpose: fetch a single transaction by UUID.

**Response 200 (JSON):** a single transaction object (same fields as `GET /api/v1/payments/transactions` `items[]`).

Errors: **400** invalid UUID; **404** not found; **500** server error.

---

### `GET /api/v1/payments/receipts/:id`

Purpose: resolve a human-readable receipt for a transaction UUID.

**Outputs:**

- If `receipt_url` is set and starts with `https://chapa.link/` → **302 Found** with `Location: <receipt_url>`
- Else if wallet topup row has `chapa_reference` but no `receipt_url` yet → **302** to `https://chapa.link/payment-receipt/{chapa_reference}`
- Else if `reason ∈ {fare, refund, transfer, refund_topup}` → **200** with `Content-Type: text/html; charset=utf-8` (HTML receipt)
- Otherwise → **404 (JSON)** `{"message":"receipt not available for this transaction"}`

Errors: **400** invalid UUID; **404** unknown transaction; **500** server error.

---

### `POST /api/v1/payments/transfers`

Purpose: record an **internal** wallet-to-wallet movement (no Chapa).

**Request body (JSON):**

```json
{
  "amount": 1.23,
  "payer_user_id": "user-123",
  "sender_wallet_id": "wallet-1",
  "receiver_wallet_id": "wallet-2",
  "receiver_id": "user-456",
  "receiver_full_name": "Receiver Name",
  "trip_id": "trip-uuid",
  "assistant_id": "assistant-uuid-or-null",
  "sub_city_id": 123,
  "message": "optional note"
}
```

**Response 200 (JSON):**

```json
{
  "transaction_id": "<uuid>",
  "tx_ref": "pay-<uuid>",
  "receipt_url": "<url or null>"
}
```

---

### `POST /api/v1/payments/refunds`

Purpose: record an **internal** refund in the ledger.

**Request/response:** same shapes as `POST /api/v1/payments/transfers` (persisted reason differs internally).

---

### `POST /api/v1/payments/withdrawals`

Purpose: initiate a Chapa transfer (merchant payout/withdrawal) and record it in the ledger as `reason = withdraw`.

**Request body (JSON):**

```json
{
  "amount": 100.0,
  "payer_user_id": "user-123",
  "account_name": "Receiver Name",
  "account_number": "1000123456789",
  "bank_code": "656",
  "withdrawal_reference": "optional-merchant-ref",
  "message": "optional note"
}
```

**Response 200 (JSON):**

```json
{
  "transaction_id": "<uuid>",
  "tx_ref": "pay-<uuid>",
  "withdrawal_reference": "merchant-or-chapa-reference",
  "status": "pending|succeeded|failed|cancelled"
}
```

Errors: **400**, **503**, **502**, **500** with JSON `{"message":"..."}`.

Validation note:

- `bank_code` is validated against Chapa `GET /v1/banks` before transfer initiation.
- Supported banks list is cached in-memory for 24 hours (TTL) to reduce upstream calls.

---

### `GET /api/v1/payments/banks/chapa`

Purpose: return Chapa-supported banks available for transfer `bank_code` selection.

**Response 200 (JSON):**

```json
{
  "items": [
    {
      "id": "1",
      "name": "Commercial Bank of Ethiopia",
      "slug": "commercial-bank-of-ethiopia",
      "code": "656",
      "currency": "ETB"
    }
  ]
}
```

Errors: **503**, **502** with JSON `{"message":"..."}`.

---

### `POST /api/v1/payments/refunds/topup`

Purpose: refund a completed Chapa wallet topup (Chapa refund API).

**Preconditions (enforced):**

- Parent transaction exists
- Parent `reason = wallet topup`
- Parent `status = succeeded`
- Parent has non-empty `chapa_reference`

**Request body (JSON):**

```json
{
  "transaction_id": "<parent topup uuid>",
  "amount": 1.23,
  "reason": "optional refund reason",
  "reference": "optional unique refund request id",
  "sender_wallet_id": "optional; defaults from parent",
  "receiver_wallet_id": "optional; defaults from parent"
}
```

Notes:

- If `amount` is omitted, no amount is sent to Chapa (full refund per Chapa).
- If `amount` is set, it must be ≤ parent amount.

**Response 200 (JSON):**

```json
{
  "transaction_id": "<new uuid>",
  "tx_ref": "pay-<uuid>",
  "chapa_refund_ref_id": "<Chapa refund ref_id>",
  "parent_transaction_id": "<parent uuid>",
  "receipt_url": "<url or null>"
}
```

Errors: **400**, **404**, **503**, **502**, **500** with JSON `{"message":"..."}`.

---

### `POST /api/v1/payments/webhooks/chapa` (or `POST {CHAPA_WEBHOOK_PATH}`)

Purpose: receive Chapa charge events; update transaction status by `tx_ref`; notify wallet service on successful topup.

**Security (optional):**

- HMAC-SHA256 of raw body using `CHAPA_WEBHOOK_SECRET`
- Compared to `Chapa-Signature` / `X-Chapa-Signature` (case-insensitive variants mentioned in API doc)
- If `CHAPA_WEBHOOK_SECRET` is empty, verification is skipped

**Request body (JSON):** at least `event`, `tx_ref`, `reference`, `type`, `status`.

**Wallet callback (on successful wallet topup):**

If the updated transaction is a `wallet topup` and the new status is `succeeded`, the service POSTs to:

`{WALLET_SERVICE_BASE_URL}{WALLET_FINALIZE_TOPUP_PATH}` (default `/api/v1/wallet/finalize-topup`) with JSON:

```json
{
  "transaction_id": "<uuid>",
  "tx_ref": "pay-<uuid>",
  "chapa_reference": "<Chapa reference from webhook>",
  "payer_user_id": "<string>",
  "receiver_wallet_id": "<string>",
  "amount": "<decimal string>",
  "currency": "ETB"
}
```

The finalize call retries up to 3 times with exponential backoff for timeout/5xx failures. If all retries fail, the event is written to a dead-letter table for background reprocessing and the webhook still returns `200`.

**Responses:**

- **200** OK (including ignored/unknown events)
- **400** invalid JSON/body read error
- **401** signature verification failed
- **500** database error

## Published RabbitMQ events

Environment:

- `RABBITMQ_URL`
- `ANALYTICS_EXCHANGE` (default `analytics_exchange`)
- `NOTIFICATION_EXCHANGE` (default `notification.exchange`)

### `analytics.transaction.completed`

Published after successful transaction completion from:

- `POST /api/v1/payments/initiate` (fare/refund rows)
- `POST /api/v1/payments/transfers`
- `POST /api/v1/payments/withdrawals` (when Chapa transfer returns success)
- `POST /api/v1/payments/refunds`
- `POST /api/v1/payments/webhooks/chapa` (`charge.success` topup update)

Payload:

```json
{
  "id": "<uuid-v4>",
  "created_at": "<RFC3339>",
  "transaction_id": "<payment transaction uuid>",
  "sub_city_id": 123,
  "amount": 50,
  "type": "fare | wallet topup | refund | transfer | refund_topup",
  "trip_id": "trip-uuid-or-null",
  "payer_user_id": "user-123"
}
```

### `notification.payment.succeeded`

Published to `notification.exchange` with routing key `notification.payment.succeeded` for successful fare-payment records (`/api/v1/payments/transfers` and fare via `/api/v1/payments/initiate`).

