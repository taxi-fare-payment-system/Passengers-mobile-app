# document_service — HTTP + Event Interface

Base path: server root on `PORT` (default `8085`).

Default content type: JSON for responses, `multipart/form-data` for uploads.

Authentication: uses **Header Trust** (API Gateway pattern).
The service trusts the following headers:
- `X-User-ID`: caller identity.
- `X-User-Role`: caller role.
- `X-Sub-City`: trusted admin sub-city scope (used for admin scoping when role is `admin`).

Sub-city ownership: this service does **not** own SubCity entities and does not query sub-city metadata. `X-Sub-City` is treated as an opaque scope identifier for filtering only.

Role normalization: `superadmin` and `super_admin` are treated as equivalent.

## Endpoints

### Health
- `GET /api/v1/documents/health`

### User / Service Endpoints
- `POST /api/v1/documents/upload` — Upload a document
- `GET /api/v1/documents/user/:user_id` — List documents for a user
- `POST /api/v1/documents/vehicle/:vehicleID/references` — Register a vehicle document reference (internal service-to-service)
- `GET /api/v1/documents/:id` — Get a specific document
- `GET /api/v1/documents/:id/status` — Lightweight status check (`id`, `status`)

### Admin Endpoints
- `GET /api/v1/documents/admin/pending` — List pending documents
- `PUT /api/v1/documents/admin/:id/approve` — Approve a document
- `PUT /api/v1/documents/admin/:id/reject` — Reject a document

---

## HTTP API Detail

### `POST /api/v1/documents/upload`
Purpose: Upload a document.

**Authorization rules:**
- Requires `X-User-ID`.
- `user_id` form field must equal `X-User-ID` unless caller role is `admin` or `super_admin`.

**Content-Type:** `multipart/form-data`

**Form fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | string | Yes | Owner of the document |
| `user_role` | string | No | Persisted role; if omitted, falls back to `X-User-Role` |
| `document_type` | string | Yes | `national_id`, `license`, `registration`, `profile_photo` |
| `sub_city_id` | integer | No | Numeric ID of the user's sub-city |
| `file` | binary | Yes | Max 5MB |

**File type rules:**
- `national_id`, `license`, `registration`: JPEG/PNG/PDF
- `profile_photo`: JPEG/PNG only

**Status behavior:**
- `profile_photo` is auto-approved on upload (`status=approved`, `verified_by=system`)
- other types start as `pending`

**Success 200 (example):**
```json
{
  "id": "doc-uuid",
  "user_id": "user-123",
  "document_type": "profile_photo",
  "status": "approved",
  "file_url": "http://localhost:8085/api/v1/documents/files/abc.jpg",
  "created_at": "2026-05-04T10:30:00Z"
}
```

---

### `GET /api/v1/documents/user/:user_id`
Purpose: List documents owned by a user.

**Authorization rules:**
- Allowed when `X-User-ID == :user_id`, or caller role is `admin` / `super_admin`.

**Behavior note:**
- For `profile_photo`, only the latest uploaded document is returned in the list.

---

### `GET /api/v1/documents/:id`
Purpose: Get one document by ID.

**Authorization rules:**
- If identity headers are provided, only owner or admin/superadmin can access.
- Trusted internal service calls without `X-User-ID` and `X-User-Role` are allowed.

---

### `GET /api/v1/documents/:id/status`
Purpose: Lightweight status endpoint for service-to-service checks.

**Success 200:**
```json
{
  "id": "doc-uuid",
  "status": "approved"
}
```

---

### `POST /api/v1/documents/vehicle/:vehicleID/references`
Purpose: Register an external document reference for a vehicle. Called internally by Vehicle Service after a document URL has been validated.

**Authorization rules:**
- Internal service-to-service call; no `X-User-ID` / `X-User-Role` enforcement on this endpoint.

**Content-Type:** `application/json`

**Request body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `document_type` | string | Yes | e.g. `INSURANCE`, `REGISTRATION` |
| `document_url` | string | Yes | Fully-qualified HTTPS URL of the document |
| `external_document_id` | string | No | ID from an upstream document store |

**Example request:**
```json
{
  "document_type": "INSURANCE",
  "external_document_id": "ext-ins-1",
  "document_url": "https://storage.example.com/vehicles/ins.pdf"
}
```

**Success 200:**
```json
{
  "document_url": "https://storage.example.com/vehicles/ins.pdf"
}
```

**Error responses:**
- `400 Bad Request`: missing `document_type` or `document_url`
- `500 Internal Server Error`: persistence failure

---

### `GET /api/v1/documents/admin/pending`
Purpose: List pending documents.

**Authorization rules:**
- Requires `X-User-Role` in `{admin, super_admin}`.
- For `admin`, sub-city scope comes from `X-Sub-City` when present.

**Query parameters:**
- `sub_city_id`: optional filter (overridden by `X-Sub-City` for admin role)
- `limit`: default `20`
- `offset`: default `0`

---

### `PUT /api/v1/documents/admin/:id/approve`
Purpose: Approve a pending document.

**Authorization rules:**
- Requires role `admin` or `super_admin`.
- For `admin` + `X-Sub-City`, target document must belong to that sub-city.

---

### `PUT /api/v1/documents/admin/:id/reject`
Purpose: Reject a pending document.

**Authorization rules:**
- Requires role `admin` or `super_admin`.
- For `admin` + `X-Sub-City`, target document must belong to that sub-city.

---

## RabbitMQ Event Interface

### Exchanges
- Document status exchange: `DOCUMENT_EVENTS_EXCHANGE` (default `document_events`)
- Analytics exchange: `ANALYTICS_EXCHANGE` (default `analytics_exchange`)

### `document.status.updated` (routing key on document exchange)
Published when a document is approved/rejected.

**Payload:**
```json
{
  "event": "document.status.updated",
  "document": {
    "id": "doc-uuid",
    "user_id": "driver-123",
    "document_type": "national_id",
    "status": "approved",
    "verified_by": "admin-456",
    "verified_at": "2026-03-29T11:00:00Z",
    "rejection_reason": null
  },
  "user_contact": {
    "phone": "+251911223344",
    "email": null
  }
}
```

`user_contact` is fetched from `GET {AUTH_SERVICE_BASE_URL}/internal/users/:user_id/contact`.
If lookup fails, event is still emitted without `user_contact`.

### Analytics events (routing keys on analytics exchange)

All analytics events include:
```json
{
  "id": "uuid-v4",
  "created_at": "RFC3339 timestamp"
}
```

- `analytics.document.uploaded` (on successful upload):
  - `document_id`, `user_id`, `document_type`, `sub_city_id`
- `analytics.document.status_updated` (on approve/reject):
  - `document_id`, `user_id`, `status`, `document_type`, `sub_city_id`

---

## Common Error Shape
Non-2xx responses return:
```json
{
  "error": "message"
}
```
