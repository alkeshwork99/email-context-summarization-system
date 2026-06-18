# API Reference

Base URL: `http://localhost:3000`

All authenticated endpoints require an `Authorization: Bearer <token>` header.
Tokens are obtained from `POST /login` and expire after 24 hours.

---

## POST /login

Authenticates an accountant and returns a signed JWT.

**Authentication:** Not required.

**Request:**

```
Content-Type: application/json

{
  "email": "mary@abc-cpa.com",
  "password": "password123"
}
```

**Success — 200 OK:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "role": "admin",
  "name": "Mary Johnson",
  "email": "mary@abc-cpa.com"
}
```

**Failure — 401 Unauthorized:**

```json
{
  "error": "Invalid credentials"
}
```

**curl example:**

```bash
curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mary@abc-cpa.com","password":"password123"}' | jq .
```

---

## GET /email_summaries/:conversation_id

Returns the AI-generated summary for an email thread. On the first request for a given
thread, Gemini is called and the result is cached in Redis and persisted to the database.
Subsequent requests return the cached result without calling Gemini.

**Authentication:** Required (any role).

**Path parameter:**

| Parameter | Description |
|-----------|-------------|
| `conversation_id` | The `conversation_id` of the email thread (e.g. `conv_001`) |

Seeded conversation IDs: `conv_001` through `conv_006`.

**Success — 200 OK:**

```json
{
  "actors": ["John Smith", "Alice Brown"],
  "concluded_discussions": ["W2 documents received and reviewed"],
  "open_action_items": [],
  "summary": "John requested W2 documents from Alice. Alice provided them promptly and John confirmed receipt. The thread is fully resolved."
}
```

**Errors:**

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{"error":"Unauthorized"}` | Missing, invalid, or expired token |
| 404 | `{"error":"Not Found"}` | No thread with that conversation_id |

**curl example:**

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@abc-cpa.com","password":"password123"}' | jq -r .token)

curl -s http://localhost:3000/email_summaries/conv_001 \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

## POST /email_summaries/:conversation_id/refresh

Forces re-analysis of an email thread. Deletes the Redis cache entry and the existing
database record, then calls Gemini again with the current thread content. Use this when
new messages have been added to a thread and the summary is stale.

**Authentication:** Required (any role).

**Path parameter:**

| Parameter | Description |
|-----------|-------------|
| `conversation_id` | The `conversation_id` of the email thread |

**Request body:** None.

**Success — 200 OK:**

Returns the freshly generated summary in the same shape as `GET /email_summaries/:id`.

```json
{
  "actors": ["John Smith", "Alice Brown"],
  "concluded_discussions": ["W2 documents received and reviewed"],
  "open_action_items": [],
  "summary": "John requested W2 documents from Alice. Alice provided them promptly and John confirmed receipt. The thread is fully resolved."
}
```

**Errors:**

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{"error":"Unauthorized"}` | Missing, invalid, or expired token |
| 404 | `{"error":"Not Found"}` | No thread with that conversation_id |

**curl example:**

```bash
curl -s -X POST http://localhost:3000/email_summaries/conv_001/refresh \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

## GET /reports/firm

Returns a summary report for the authenticated accountant's firm: the firm name and the
number of clients that have at least one email summary.

**Authentication:** Required. **Role: admin only.** Regular accountants and superusers
receive 403.

**Success — 200 OK:**

```json
{
  "firm_name": "ABC CPA",
  "total_clients_with_summaries": 2
}
```

**Errors:**

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{"error":"Unauthorized"}` | Missing, invalid, or expired token |
| 403 | `{"error":"Forbidden"}` | Authenticated but not an admin |

**curl example (login as admin first):**

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"mary@abc-cpa.com","password":"password123"}' | jq -r .token)

curl -s http://localhost:3000/reports/firm \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

## GET /reports/global

Returns a summary report across all firms. Each entry includes the firm name and the number
of its clients with at least one email summary. Only available to superusers.

**Authentication:** Required. **Role: superuser only.** Admins and regular accountants
receive 403.

**Success — 200 OK:**

```json
[
  {
    "firm_name": "ABC CPA",
    "total_clients_with_summaries": 2
  },
  {
    "firm_name": "XYZ CPA",
    "total_clients_with_summaries": 1
  }
]
```

**Errors:**

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{"error":"Unauthorized"}` | Missing, invalid, or expired token |
| 403 | `{"error":"Forbidden"}` | Authenticated but not a superuser |

**curl example (login as superuser first):**

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@system.com","password":"password123"}' | jq -r .token)

curl -s http://localhost:3000/reports/global \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

## Seeded Accounts

| Email | Password | Role | Firm |
|-------|----------|------|------|
| john@abc-cpa.com | password123 | accountant | ABC CPA |
| mary@abc-cpa.com | password123 | admin | ABC CPA |
| david@xyz-cpa.com | password123 | accountant | XYZ CPA |
| admin@system.com | password123 | superuser | ABC CPA |

## Seeded Conversations

| ID | Client | Subject |
|----|--------|---------|
| conv_001 | Alice Brown | Need W2 Documents |
| conv_002 | Alice Brown | 1099 Forms |
| conv_003 | Alice Brown | Tax Deductions |
| conv_004 | Bob Green | Filing Extension |
| conv_005 | Charlie Davis | Business Expenses |
| conv_006 | Charlie Davis | Previous Year Returns |
