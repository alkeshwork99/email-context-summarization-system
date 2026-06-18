# Email Context & Summarization System

Backend Engineer Case Study — Ascend

---

# Problem Statement

Accountants at a CPA firm share clients but often lack visibility into each other's email history. When multiple accountants communicate with the same client, they may ask duplicate questions, miss previously resolved discussions, and create a fragmented client experience.

This system solves that by generating unified AI-powered summaries across email threads and at the client level. Summaries capture:

- Who participated
- What has already been resolved
- What still requires action

Summary text is encrypted at rest, cached in Redis, and available to authorized accountants through APIs and a browser interface.

---

# Features

- JWT Authentication with 24-hour expiry
- AI-powered summaries using Gemini 2.5 Flash
- AES-256-GCM encryption for summary text
- Redis cache-aside pattern to avoid repeated Gemini calls
- Thread-level refresh endpoint
- Client-level synthesis across multiple threads
- Role-based reporting
- Browser UI with authentication and navigation
- OpenTelemetry tracing
- Structured correlated logs
- RSpec test suite

---

# Browser Interface

- Sign In page
- Dashboard
- Client list
- Client details
- Email thread view
- Thread summary page
- Client summary page
- Refresh summary actions
- Firm report page
- Global report page
- Custom error pages

---

# Tech Stack

| Layer | Technology |
|---------|------------|
| Framework | Rails 8.1 |
| Language | Ruby 3.3.10 |
| Database | PostgreSQL 17 |
| Cache | Redis 8 |
| LLM | Gemini 2.5 Flash |
| HTTP Client | Faraday |
| Auth | JWT + BCrypt |
| Encryption | AES-256-GCM |
| Observability | OpenTelemetry SDK + Rack instrumentation + structured Rails logs |
| Testing | RSpec + FactoryBot + Faker |
| Linting | rubocop-rails-omakase |
| Security | Brakeman + Bundler Audit |

---

# Project Structure

```text
app/
├── controllers/
├── models/
├── services/
├── views/
└── helpers/

spec/
├── factories/
├── models/
├── requests/
└── services/

docs/
├── architecture.md
├── api.md
├── decisions.md
└── ai_usage.md
```

---

# Docs Map

Start with this root README for the current system overview.

Supporting references:


- [USER_GUIDE.md](./USER_GUIDE.md) — browser walkthrough and role-based usage
- [docs/local_setup_guide.md](./docs/local_setup_guide.md) — local Docker setup reference
- [docs/api.md](./docs/api.md) — API endpoint reference
- [docs/architecture.md](./docs/architecture.md) — schema and architecture diagrams
- [docs/ai_usage.md](./docs/ai_usage.md) — AI usage disclosure

---

# Seed Accounts

| Email | Password | Role |
|---------|----------|------|
| john@abc-cpa.com | password123 | accountant |
| bob@abc-cpa.com | password123 | accountant |
| mary@abc-cpa.com | password123 | admin |
| admin@system.com | password123 | superuser |

---

# Development Data

The application currently runs on seeded sample data stored in PostgreSQL.

Seed data includes:

- Multiple firms
- Multiple accountants
- Clients
- Email threads
- Email messages

The dataset intentionally demonstrates:

- Duplicate requests across accountants
- Contradictions across threads
- Cross-thread client synthesis
- Role-based permissions
- Reporting workflows

Today, `MockEmailService` reads that seeded data and acts as the email-source boundary that a
future mailbox integration can replace. Gemini calls are real service-layer HTTP requests when
summary generation happens, but the underlying email source for development and testing is local
seed data rather than Microsoft 365 or Outlook.

---

# Environment Variables

Create a `.env` file:

```env
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_NAME=email_context_api_development
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres

REDIS_URL=redis://redis:6379/0

JWT_SECRET=<your-secret>
ENCRYPTION_KEY=<64-character-hex-string>
GEMINI_API_KEY=<your-gemini-api-key>
```

Generate an encryption key:

```bash
ruby -e "puts SecureRandom.hex(32)"
```

---

# Local Setup

## Clone Repository

```bash
git clone <repository-url>
cd email_context_api
```

---

## Start Containers

```bash
docker-compose up -d --build
```

---

## Enter Application Container

```bash
docker-compose exec app bash
```

---

## Create Database

```bash
bundle exec rails db:create
```

---

## Run Migrations

```bash
bundle exec rails db:migrate
```

---

## Seed Data

```bash
bundle exec rails db:seed
```

---

## Start Rails Server

Important:

```bash
bundle exec rails server -b 0.0.0.0 -p 3000
```

Do not run:

```bash
rails s
```

because Puma will bind to localhost inside the container.

---

Application:

- Browser UI

```text
http://localhost:3000/sign_in
```

- API

```text
http://localhost:3000
```

---

# Docker Commands

### Enter container

```bash
docker-compose exec app bash
```

### Rails console

```bash
docker-compose exec app rails c
```

### Run migrations

```bash
docker-compose exec app rails db:migrate
```

### Seed database

```bash
docker-compose exec app rails db:seed
```

### Reset database

```bash
docker-compose exec app rails db:reset
```

### Stop containers

```bash
docker-compose down
```

### Start containers

```bash
docker-compose up -d
```

### Rebuild containers

```bash
docker-compose down
docker-compose up -d --build
```

---

# Docker Compose Fix

If:

```bash
docker-compose up
```

throws:

```text
KeyError: 'ContainerConfig'
```

run:

```bash
docker-compose down
docker container prune -f
docker-compose up -d --build
```

---

# Running Tests

```bash
docker-compose exec app bundle exec rspec
```

---

# Quality Gates

### Rubocop

```bash
docker-compose exec app bundle exec rubocop
```

### Brakeman

```bash
docker-compose exec app bundle exec brakeman -q
```

### Bundler Audit

```bash
docker-compose exec app bundle exec bundler-audit check --update
```

---

# API Endpoints

| Method | Endpoint |
|----------|----------|
| POST | /login |
| GET | /email_summaries/:conversation_id |
| POST | /email_summaries/:conversation_id/refresh |
| GET | /client_summaries/:client_id |
| POST | /client_summaries/:client_id/refresh |
| GET | /reports/firm |
| GET | /reports/global |

Full reference:

```text
docs/api.md
```

---

# Observability

The application uses:

- OpenTelemetry SDK
- Rack instrumentation
- Manual spans around summary and report workflows
- Structured JSON Rails logs
- Trace and span correlation IDs

Observability is intentionally local-only and does not require:

- Jaeger
- Tempo
- Grafana
- Prometheus
- OTLP collectors

---

# Current Gemini Integration

## Current Flow

Gemini is invoked synchronously from the Rails service layer through Faraday.

Thread summary generation today:

```text
Request
    ↓
SummaryService.generate(conversation_id)
    ↓
SummaryCacheService.fetch                # Redis cache check
    ↓
EmailSummary lookup                      # PostgreSQL summary check
    ↓
MockEmailService.fetch_thread/messages   # seeded PostgreSQL email data
    ↓
SummaryCacheService.lock                 # prevent duplicate concurrent generation
    ↓
GeminiClient.generate_summary
    ↓
Gemini REST API
    ↓
Encrypt summary
    ↓
Persist EmailSummary
    ↓
Write Redis cache
    ↓
SummaryCacheService.unlock
    ↓
Return response
```

Client summary generation today:

```text
Request
    ↓
ClientSummaryService.generate(client_id)
    ↓
SummaryCacheService.fetch                # Redis cache check
    ↓
ClientSummary lookup                     # PostgreSQL summary check
    ↓
MockEmailService.fetch_client_threads    # seeded PostgreSQL thread data
    ↓
SummaryService.generate for each thread  # thread summaries loaded first
    ↓
Aggregate thread summaries
    ↓
SummaryCacheService.lock
    ↓
GeminiClient.generate_client_summary
    ↓
Gemini REST API
    ↓
Encrypt summary
    ↓
Persist ClientSummary
    ↓
Write Redis cache
    ↓
SummaryCacheService.unlock
    ↓
Return response
```

Refresh remains explicit: the app deletes the cached and persisted summary state first, then
re-runs generation on demand.

## Current Limitations

- Gemini calls happen inline during the request-response cycle, so cache misses can increase user-facing latency.
- The app uses seeded PostgreSQL email data through `MockEmailService`; there is no live Microsoft Graph or Outlook ingestion today.
- Locking is per summary key and prevents duplicate concurrent generation for the same item, but it does not yet provide a full background work queue or broader throughput controls.
- Summary generation is explicitly refreshed rather than automatically triggered by mailbox events.

## Future Scaling Options

### Microsoft Graph API Integration

The current boundary is:

```text
MockEmailService
```

The likely production replacement is:

```text
GraphEmailService
```

That would let the application retrieve real messages from Microsoft 365 or Outlook without
rewriting the summarization orchestrators.

### Preferred Ingestion Path: Webhooks First

If Microsoft Graph notifications are available, the preferred future ingestion model is:

```text
Microsoft 365 / Outlook
        ↓
Graph webhook notification
        ↓
Rails endpoint
        ↓
Persist message metadata/content
        ↓
Enqueue summarization work
        ↓
Worker processes summaries
        ↓
Cache + database updated
```

Webhook-driven ingestion is preferable because it reduces polling overhead and lets the app react
to mailbox changes near real time.

### Fallback Ingestion Path: Background Sync

If webhooks are unavailable, delayed, or incomplete, the fallback would be a scheduled background
sync job that polls Graph periodically, persists new messages, and then enqueues summarization.

### First Scaling Step: Active Job + Solid Queue

The most practical next step in this codebase is Rails-native background processing with
`Active Job + Solid Queue`, because queue infrastructure already exists in the project.

That future flow would look like:

```text
Request or mailbox event
        ↓
Enqueue job
        ↓
Solid Queue worker
        ↓
Gemini API call
        ↓
Persist summary
        ↓
Update Redis cache
```

This would reduce request blocking, isolate failures better, and give the app retries and better
operational control.

### Queueing and Throughput Controls

After background jobs are introduced, useful scaling options include:

- queueing Gemini-backed work instead of processing every cache miss inline
- sequential or bounded-concurrency workers per queue
- retries with exponential backoff
- dead-letter handling for repeated failures
- per-user and per-firm rate limiting
- backpressure controls when Gemini capacity is constrained

### Alternative Queue Runtimes

Other queue systems are possible later, but they are not the primary next step for this Rails app:

- Sidekiq or Resque could be adopted if the project wants a Redis-first Ruby worker model
- BullMQ is only worth considering if the system evolves toward separate Node.js worker services or a broader polyglot queue architecture

---

## Pagination

Global reports currently return all firms.

Future versions may support:

- Offset pagination
- Cursor pagination

---

## Observability Backends

Current implementation uses local console exporters.

Future deployments could export traces to:

- OTLP collectors
- Jaeger
- Tempo
- Grafana

without changing application instrumentation.

---

# Submission Notes

This project was developed and tested entirely in Docker using local PostgreSQL and Redis instances.

The current implementation intentionally favors:

- simplicity
- explicit service boundaries
- readability
- deterministic testing
- minimal infrastructure requirements

while leaving clear paths for future scaling and production integrations.
