# Vehicle Service Interface

This document describes **every HTTP endpoint** exposed by Vehicle Service and the **data structures** (JSON) going in/out.

Base URL (local): `http://localhost:8083`

## Conventions

- **Content-Type**: send JSON bodies with `Content-Type: application/json`.
- **Authentication**:
  - `GET /api/v1/vehicles/healthz` is public.
  - `GET /api/v1/vehicles/metricsz` is public (lightweight metrics snapshot).
  - All other endpoints require `Authorization: Bearer <jwt>`.
- **Path params**:
  - `:id` is vehicle identifier string (opaque ID).
  - `:driverId` is driver identifier string.
  - `:ownerId` is owner identifier string.
- **Error response envelope** (non-2xx):

```json
{
  "traceId": "string",
  "code": "string",
  "message": "string"
}
```

## Data structures

### Vehicle object

```json
{
  "id": "vehicle-1",
  "ownerId": "owner-1",
  "plateNumber": "AA-1001",
  "capacity": 14,
  "vehicleTypeId": "type-uuid",
  "approvalState": "APPROVED",
  "approvedAt": "2026-04-29T00:00:00Z",
  "rejectedAt": null,
  "reviewedAt": "2026-04-29T00:00:00Z",
  "reviewedBy": "admin-1",
  "reviewReason": null,
  "metadata": {
    "color": "white"
  },
  "version": 3,
  "createdAt": "2026-04-29T00:00:00Z",
  "updatedAt": "2026-04-29T00:00:00Z",
  "deletedAt": null
}
```

### `POST /api/v1/vehicles` request

```json
{
  "ownerId": "owner-1",
  "plateNumber": "AA-1001",
  "capacity": 14,
  "vehicleTypeId": "type-uuid",
  "metadata": {
    "color": "white"
  }
}
```

### `PUT /api/v1/vehicles/:id` request

```json
{
  "version": 1,
  "plateNumber": "AA-1001",
  "capacity": 16,
  "metadata": {
    "color": "blue"
  }
}
```

`plateNumber`, `capacity`, `metadata` are optional for partial update; `version` is required.

### Vehicle list response (`GET /api/v1/vehicles`, `GET /api/v1/vehicles/owners/:ownerId`)

```json
{
  "items": [
    {
      "id": "vehicle-1",
      "ownerId": "owner-1",
      "plateNumber": "AA-1001",
      "capacity": 14,
      "approvalState": "APPROVED",
      "version": 3
    }
  ],
  "pageInfo": {
    "page": 0,
    "pageSize": 20,
    "total": 1
  }
}
```

### `POST /api/v1/vehicles/:id/approval/approve` request

```json
{
  "version": 3
}
```

### `POST /api/v1/vehicles/:id/approval/reject` request

```json
{
  "version": 3,
  "reason": "Insurance document expired"
}
```

### `POST /api/v1/vehicles/:id/approval/resubmit` request

```json
{
  "version": 4
}
```

### Driver assignment response

```json
{
  "id": "uuid",
  "vehicleId": "vehicle-1",
  "driverId": "driver-1",
  "status": "ACTIVE",
  "assignedAt": "2026-04-29T00:00:00Z",
  "unassignedAt": null
}
```

### `POST /api/v1/vehicles/:id/driver-assignments` request

```json
{
  "driverId": "driver-1"
}
```

### Vehicle eligibility response (`GET /api/v1/vehicles/:id/eligibility`)

```json
{
  "vehicleId": "vehicle-1",
  "assignable": true,
  "approvalState": "APPROVED"
}
```

### Vehicle type object

```json
{
  "id": "type-uuid",
  "name": "minibus",
  "pricePerKm": 15.0,
  "capacity": 14,
  "createdAt": "2026-04-29T00:00:00Z",
  "updatedAt": "2026-04-29T00:00:00Z"
}
```

### `POST /api/v1/vehicles/:id/documents` request

```json
{
  "documentType": "INSURANCE",
  "externalDocumentId": "ext-ins-1",
  "documentUrl": "https://example.com/insurance.pdf"
}
```

### Document link response

```json
{
  "id": "uuid",
  "vehicleId": "vehicle-1",
  "documentType": "INSURANCE",
  "documentUrl": "https://document-service.example/files/abc",
  "externalDocumentId": "ext-ins-1",
  "status": "ACTIVE",
  "createdAt": "2026-04-29T00:00:00Z",
  "updatedAt": "2026-04-29T00:00:00Z"
}
```

### `GET /api/v1/vehicles/metricsz` response

```json
{
  "service": "vehicle-service",
  "requestTotal": 100,
  "requestErrors": 3,
  "errorRate": 0.03,
  "timestamp": "2026-04-29T00:00:00Z"
}
```

## Endpoints

### `GET /api/v1/vehicles/healthz`

Operational health check.

- **Request body**: none
- **Responses**:
  - `200 OK`

```json
{ "ok": true }
```

---

### `GET /api/v1/vehicles/metricsz`

Lightweight in-process metrics hook endpoint.

- **Request body**: none
- **Responses**:
  - `200 OK`: metrics snapshot object

---

### `POST /api/v1/vehicles`

Create vehicle.

- **Request body**: `POST /api/v1/vehicles` request
- **Success response**:
  - `201 Created`: vehicle object
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid plate / invalid capacity
  - `401 Unauthorized`
  - `403 Forbidden`: caller cannot create for owner
  - `409 Conflict`: duplicate active plate

---

### `PUT /api/v1/vehicles/:id`

Update vehicle fields (partial) with optimistic concurrency.

- **Request body**: `PUT /api/v1/vehicles/:id` request
- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid input
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: version conflict / plate conflict

---

### `DELETE /api/v1/vehicles/:id`

Soft-delete vehicle.

- **Query params**:
  - `version` (required for optimistic concurrency)
- **Success response**:
  - `204 No Content`
- **Error responses**:
  - `400 Bad Request`: missing/invalid version
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: version conflict / active dependency exists

---

### `GET /api/v1/vehicles/:id`

Get vehicle by ID.

- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `401/403` auth failures
  - `404 Not Found`

---

### `GET /api/v1/vehicles`

List vehicles (paginated, optional filters).

- **Query params**:
  - `page` (default `0`)
  - `pageSize` (default `20`)
  - `status` (optional)
  - `ownerId` (optional)
  - `sub_city_id` (optional, superadmin only)
- **Headers**:
  - `X-Sub-City` (admin-scoped filter injected by gateway)
- **Success response**:
  - `200 OK`: vehicle list response
- **Error responses**:
  - `401/403` auth failures

---

### `GET /api/v1/vehicles/:id/eligibility`

Check whether vehicle is route-assignable (`APPROVED` required).

- **Success response**:
  - `200 OK`: eligibility response
- **Error responses**:
  - `401/403` auth failures
  - `404 Not Found`

---

### `POST /api/v1/vehicles/:id/approval/approve`

Approve vehicle (admin only).

- **Request body**: `POST /api/v1/vehicles/:id/approval/approve` request
- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `400 Bad Request`: invalid JSON
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: invalid transition / version conflict

---

### `POST /api/v1/vehicles/:id/approval/reject`

Reject vehicle (admin only).

- **Request body**: `POST /api/v1/vehicles/:id/approval/reject` request
- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `400 Bad Request`: invalid JSON / missing rejection reason
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: invalid transition / version conflict

---

### `POST /api/v1/vehicles/:id/approval/resubmit`

Resubmit rejected vehicle to pending approval (owner of vehicle or admin).

- **Request body**: `POST /api/v1/vehicles/:id/approval/resubmit` request
- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `400 Bad Request`: invalid JSON
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: invalid transition / version conflict

---

### `POST /api/v1/vehicles/:id/driver-assignments`

Assign or reassign driver to vehicle.

- **Request body**: `POST /api/v1/vehicles/:id/driver-assignments` request
- **Success response**:
  - `200 OK`: driver assignment response
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid input
  - `401/403` auth failures
  - `404 Not Found`
  - `409 Conflict`: invalid transition (vehicle not approved) / assignment conflict / `DRIVER_NOT_VERIFIED`

---

### `DELETE /api/v1/vehicles/:id/driver-assignments/:driverId`

Unassign active driver from vehicle.

- **Request body**: none
- **Success response**:
  - `204 No Content`
- **Error responses**:
  - `400 Bad Request`: invalid input
  - `401/403` auth failures
  - `404 Not Found`

---

### `GET /api/v1/vehicles/owners/:ownerId`

List vehicles by owner.

- **Query params**:
  - `page` (default `0`)
  - `pageSize` (default `20`)
- **Success response**:
  - `200 OK`: vehicle list response
- **Error responses**:
  - `401/403` auth failures

---

### `GET /api/v1/vehicles/drivers/:driverId`

Get active assigned vehicle by driver ID.

- **Success response**:
  - `200 OK`: vehicle object
- **Error responses**:
  - `401/403` auth failures
  - `404 Not Found`

---

### `POST /api/v1/vehicles/:id/documents`

Link/register a document reference through the document adapter boundary.

- **Allowed roles**: `admin`, `driver-assistant`, `owner` (owner must own the vehicle)
- **Request body**: `POST /api/v1/vehicles/:id/documents` request
- **Success response**:
  - `200 OK`: document link response
- **Error responses**:
  - `400 Bad Request`: invalid JSON / invalid URL / invalid type
  - `401/403` auth failures
  - `404 Not Found`
  - `502 Bad Gateway`: document service unavailable

---

### `POST /api/v1/vehicles/types`

Create vehicle type (superadmin only).

- **Request body**:

```json
{ "name": "minibus", "pricePerKm": 15.0, "capacity": 14 }
```

- **Success response**:
  - `201 Created`: vehicle type object

---

### `GET /api/v1/vehicles/types`

List all vehicle types.

- **Success response**:
  - `200 OK`

```json
{ "items": [{ "id": "type-uuid", "name": "minibus", "pricePerKm": 15.0, "capacity": 14 }] }
```

---

### `GET /api/v1/vehicles/types/:id`

Get vehicle type by ID.

- **Success response**:
  - `200 OK`: vehicle type object

---

### `PATCH /api/v1/vehicles/types/:id`

Update vehicle type tariff fields (superadmin only).

- **Request body**:

```json
{ "pricePerKm": 17.5 }
```

- **Success response**:
  - `200 OK`: vehicle type object

---

### `DELETE /api/v1/vehicles/types/:id`

Delete vehicle type (superadmin only, blocked when linked vehicles exist).

- **Success response**:
  - `204 No Content`

## Outbound integrations

When Vehicle Service calls other services, it uses the `/api/v1/<service-name>` prefix:

- **Route Service**: `GET /api/v1/routes/vehicles/by-subcity?sub_city_id=<uint>`
- **Document Service**: `POST /api/v1/documents/vehicle/:vehicleId/references`

