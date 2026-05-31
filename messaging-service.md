# Messaging Service Interface
Base URL: `http://localhost:8087`
## HTTP Endpoints
### Public OTP Contract (Auth Service Integration)
#### `POST /api/v1/messaging/otp/send`
- Auth: none
- Request:
```json
{
  "recipient": "0911223344",
  "type": "sms"
}
```
- `200`:
```json
{
  "message": "OTP sent successfully"
}
```
- `429`: rate limit exceeded (`5/min`)

Behavior:
- OTP is stored against `recipient`
- TTL is 5 minutes

#### `POST /api/v1/messaging/otp/verify`
- Auth: none
- Request:
```json
{
  "recipient": "0911223344",
  "code": "123456"
}
```
- `200` valid:
```json
{
  "valid": true
}
```
- `200` invalid:
```json
{
  "valid": false
}
```
- `404`: no OTP found for recipient (expired or never sent)
Behavior:
- OTP is invalidated immediately after successful verification (replay-safe)

### Direct Message Endpoints (JWT Required)

#### `POST /api/v1/messaging/messages/sms`
Queues an SMS message.

#### `POST /api/v1/messaging/messages/email`
Queues an email message.

#### `GET /api/v1/messaging/messages/status/:id`
Returns persisted message status (`pending`, `sent`, `failed`).

### Notification Endpoints (Internal Transition Only)

These endpoints are deprecated transition paths and should not be exposed publicly via gateway routing:
- `POST /api/v1/messaging/notifications/welcome`
- `POST /api/v1/messaging/notifications/payment`

Both accept optional `notification_id` and are idempotent when provided.

## RabbitMQ Delivery Worker Interface

Messaging Service consumes delivery jobs from:

- Exchange: `delivery.direct`
- Type: `direct`

### SMS Consumer
- Queue: `delivery.sms.worker`
- Routing key: `delivery.sms`

Expected payload:
```json
{
  "to": "+251911223344",
  "message": "Your payment of 50 ETB has been received.",
  "metadata": {
    "user_id": "user-uuid",
    "notification_id": "notif-uuid"
  }
}
```

### Email Consumer
- Queue: `delivery.email.worker`
- Routing key: `delivery.email`

Expected payload:
```json
{
  "to": "user@example.com",
  "subject": "Payment Received",
  "body": "Plain text fallback",
  "html": "<h1>Payment Received</h1><p>50 ETB</p>",
  "reply_to": "support@example.com",
  "metadata": {
    "user_id": "user-uuid",
    "notification_id": "notif-uuid"
  }
}
```

## Delivery Guarantees and Retry
- Twilio/Resend dispatch retries up to 3 times with exponential backoff
- On final failure, message status is set to `failed` and message is acknowledged
- Duplicate `notification_id` values are skipped with 24-hour idempotency TTL
## Required Environment Variables
```env
PORT=8087
RABBITMQ_URL=amqp://user:pass@rabbitmq:5672/
DELIVERY_EXCHANGE=delivery.direct
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_FROM_NUMBER=+1...
RESEND_API_KEY=...
RESEND_FROM_EMAIL=noreply@yourapp.com
```
