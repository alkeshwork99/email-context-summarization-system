# User Guide

## Introduction

The Email Context & Summarization System helps accountants at CPA firms stay informed
about client email history.

Multiple accountants often work with the same client but have no visibility into each
other's email exchanges. This creates gaps — accountants ask duplicate questions, miss
important context, and create a fragmented client experience.

This system solves that by providing two levels of AI-generated summaries:

- **Thread summaries** — who was involved, what was resolved, and what is still pending within a single email thread
- **Client summaries** — a cross-thread synthesis for an entire client, revealing duplicate requests across accountants and contradictions (e.g., one accountant closed a thread as complete while another discovered something was still missing)

Any accountant at the firm can view either level of summary without reading every message.

---

## Signing In

Open a browser and go to:

```
http://localhost:3000/sign_in
```

Enter your email and password, then click **Sign In**.

### Available Accounts

| Name | Email | Password | Firm | Role |
|------|-------|----------|------|------|
| John Smith | `john@abc-cpa.com` | `password123` | ABC CPA | Accountant |
| Bob Carter | `bob@abc-cpa.com` | `password123` | ABC CPA | Accountant |
| Mary Johnson | `mary@abc-cpa.com` | `password123` | ABC CPA | Admin |
| David Wilson | `david@xyz-cpa.com` | `password123` | XYZ CPA | Accountant |
| System Admin | `admin@system.com` | `password123` | — | Superuser |

If you enter incorrect credentials, an error message appears below the navigation bar.

---

## Navigation Bar

After signing in, a navigation bar appears at the top of every page with the following
links:

- **Dashboard** — return to the home page
- **Clients** — view the client list for your firm
- **Reports** — visible only to admins and superusers
- **Sign Out** — end your session

---

## Roles and Permissions

### Accountant

Can view the dashboard, all clients in the firm, email threads, individual messages,
thread-level summaries, and client-level summaries. Can refresh both summary types at any time.

Cannot access reports.

### Admin

Everything an accountant can do, plus access to the **Firm Report**, which shows how
many clients in the firm have summaries.

### Superuser

Everything an admin can do, plus access to the **Global Report**, which shows summary
counts across all firms.

---

## Viewing Clients

1. Click **Clients** in the navigation bar.
2. A table lists all clients for your firm — name, email, and firm.
3. Click a client's name to open their detail page.

The detail page shows the client's contact information, a **Client Summary** button, and a list of their email threads.

---

## Viewing Email Threads

On a client's detail page, the **Email Threads** table lists all threads associated
with that client.

Click a thread subject to open it.

---

## Reading Messages

The thread page shows all messages in chronological order (oldest first).

Each message displays:

- **From** — the sender's email address
- **Sent** — the date and time the message was sent
- The full message body

---

## Viewing a Summary

From a thread page, click **View Summary**.

The summary page is divided into four sections:

- **Summary** — a paragraph-level overview of the entire conversation
- **Actors** — everyone who participated in the thread
- **Concluded Discussions** — topics or questions that were fully resolved
- **Open Action Items** — things that still need to be done

If no summary exists yet, one is generated automatically the first time you visit
this page.

---

## Viewing a Client Summary

From a client's detail page, click **View Client Summary**.

The client summary synthesises all email threads for that client into a single view.
It is generated from the thread-level summaries, not from raw email messages, so it
reflects the state of the entire relationship — not just one conversation.

The page is divided into four sections:

- **Summary** — an overview of the client's complete status across all threads
- **Actors** — everyone who has participated in any thread with this client
- **Concluded Discussions** — topics fully resolved across all threads
- **Open Action Items** — everything still outstanding across all threads

The client summary is especially useful for spotting:

- **Duplicate requests** — the same item (e.g., home office receipts) asked by two different accountants in separate threads
- **Contradictions** — one accountant closed a thread as complete while another thread shows something is still missing

If no client summary exists yet, one is generated automatically on the first visit.

---

## Refreshing a Thread Summary

If new messages have arrived since the last summary was generated, click
**Refresh Summary** from the thread summary page.

This discards both the thread summary and the client-level synthesis (since the client
summary is derived from thread summaries). Both are regenerated on the next request.

Use this whenever a thread has grown and the existing summary is out of date.

---

## Refreshing a Client Summary

From the client summary page, click **Refresh Client Summary**.

This discards the client-level synthesis and regenerates it from the current thread
summaries. Individual thread summaries are not discarded — only the cross-thread layer.

Use this if a thread was recently refreshed or a new thread was added for the client.

---

## Reports

### Firm Report (admin only)

Available from the **Reports** link in the navigation bar.

Shows the firm name and how many clients in that firm have a generated client-level summary.

### Global Report (superuser only)

Available from the **Reports** link in the navigation bar.

Shows the same counts for every firm in the system.

---

## Testing Cross-Accountant Caching

Use this walkthrough to verify that a client summary generated by one accountant is
served from cache to any other accountant at the same firm — with no Gemini API call.

**Step 1 — Sign in as John Smith**

```
Email:    john@abc-cpa.com
Password: password123
```

**Step 2 — Generate Alice Brown's client summary**

Clients → Alice Brown → View Client Summary.

The first visit generates the summary (calls Gemini), stores it in the database, and
caches it in Redis under the key `client_summary:{alice_id}`.

**Step 3 — Sign out**

Click **Sign Out** in the navigation bar.

**Step 4 — Sign in as Bob Carter (second accountant, same firm)**

```
Email:    bob@abc-cpa.com
Password: password123
```

**Step 5 — View Alice Brown's client summary**

Clients → Alice Brown → View Client Summary.

The page loads immediately with the same result John saw. The cache key is
`client_summary:{alice_id}` — not tied to any specific accountant — so Bob gets John's
cached result with no Gemini API call.

**Expected result:** identical summary text, actors, concluded discussions, and open
action items as John saw. No Gemini API call is made.

**Step 6 — Verify refresh updates for all accountants**

While signed in as Bob, click **Refresh Client Summary**. Sign out, sign back in as
John, and view Alice's summary again — John now sees the refreshed result because the
cache key is shared across the entire firm.

---

## Error Pages

| Page | Meaning | What to do |
|------|---------|------------|
| 401 Unauthorized | You are not signed in | Click **Sign In** |
| 403 Forbidden | Your role does not allow this page | Click **Dashboard** |
| 404 Not Found | The page does not exist | Click **Dashboard** |
| 500 Internal Server Error | Something went wrong on the server | Click **Dashboard** and try again |
