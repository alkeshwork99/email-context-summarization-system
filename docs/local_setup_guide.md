# Email Context API - Local Setup Guide (Docker)

## 1. Clone the Repository

```bash
git clone <repository-url>
cd email_context_api
```

---

## 2. Build and Start Docker Containers

Build images and start all services:

```bash
docker-compose up --build
```

Or run in detached mode:

```bash
docker-compose up -d --build
```

Expected containers:

* `email_context_api_app`
* `email_context_api_db`
* `email_context_api_redis`

---

## 3. Verify Running Containers

```bash
docker ps
```

---

## 4. Enter the Application Container

```bash
docker-compose exec app bash
```

You should see:

```bash
root@<container-id>:/app#
```

---

## 5. Create Databases

Inside the container:

```bash
rails db:create
```

---

## 6. Run Migrations

```bash
rails db:migrate
```

---

## 7. Seed Sample Data

```bash
rails db:seed
```

Expected output:

```text
Cleaning database...
Creating firms...
Creating accountants...
Creating clients...
Creating threads...
Creating messages...
Done!
```

---

## 8. Access the Application

Open:

```text
http://localhost:3000
```

---

## 9. Rails Console (Optional)

Open Rails console:

```bash
rails c
```

Example:

```ruby
alice = Client.find_by(name: "Alice Brown")
ClientSummaryService.generate(alice.id)
```

Exit console:

```ruby
exit
```

---

# Useful Docker Commands

## View Running Containers

```bash
docker ps
```

---

## Enter Container

```bash
docker-compose exec app bash
```

---

## Open Rails Console

```bash
docker-compose exec app rails c
```

---

## Run Migrations

```bash
docker-compose exec app rails db:migrate
```

---

## Run Seeds

```bash
docker-compose exec app rails db:seed
```

---

## Restart Application Container

```bash
docker-compose restart app
```

---

## View Rails Logs

```bash
docker-compose logs -f app
```

---

## Access PostgreSQL

```bash
docker-compose exec db psql -U postgres
```

---

## Access Redis

```bash
docker-compose exec redis redis-cli
```

---

# Database Reset

### Complete Reset

```bash
docker-compose exec app rails db:drop
docker-compose exec app rails db:create
docker-compose exec app rails db:migrate
docker-compose exec app rails db:seed
```

Or simply:

```bash
docker-compose exec app rails db:reset
```

---

# Stop Containers

```bash
docker-compose down
```

---

# Start Existing Containers

Foreground:

```bash
docker-compose up
```

Detached:

```bash
docker-compose up -d
```

---

# Rebuild Containers

```bash
docker-compose down
docker-compose up --build -d
```

---

# Complete Fresh Setup

```bash
git clone <repository-url>
cd email_context_api

docker-compose up -d --build

docker-compose exec app rails db:create
docker-compose exec app rails db:migrate
docker-compose exec app rails db:seed
```

Open:

```text
http://localhost:3000
```

---

# Access Sample Users

## Accountant

```text
Email: john@abc-cpa.com
Password: password123
```

```text
Email: bob@abc-cpa.com
Password: password123
```

---

## Admin

```text
Email: mary@abc-cpa.com
Password: password123
```

---

## Super Admin

```text
Email: admin@system.com
Password: password123
```

---

# Daily Development Workflow

Start containers:

```bash
docker-compose up -d
```

Enter application container:

```bash
docker-compose exec app bash
```

Open Rails console:

```bash
rails c
```

Run migrations:

```bash
rails db:migrate
```

Run seeds:

```bash
rails db:seed
```

Stop containers:

```bash
docker-compose down
```

---

# Troubleshooting

## Error: `KeyError: 'ContainerConfig'`

If running:

```bash
docker-compose up -d
```

or

```bash
docker-compose up --build
```

produces:

```text
KeyError: 'ContainerConfig'
```

this is usually caused by stale containers from a previous Docker Compose run.

### Step 1: Stop and Remove Containers

```bash
docker-compose down
```

---

### Step 2: Remove Stopped Containers

```bash
docker container prune -f
```

---

### Step 3: Rebuild Everything

```bash
docker-compose up --build -d
```

Expected:

```text
Creating network "email_context_api_default" ...
Building app ...
Successfully built ...
Successfully tagged email_context_api_app:latest

Creating email_context_api_redis ... done
Creating email_context_api_db    ... done
Creating email_context_api_app   ... done
```

---

### If Problem Persists

List containers:

```bash
docker ps -a
```

Remove the app container manually:

```bash
docker rm -f email_context_api_app
```

Then rebuild:

```bash
docker-compose up --build -d
```

---

# Application Opens But Browser Shows

```text
ERR_EMPTY_RESPONSE
```

or

```text
localhost didn't send any data
```

This happens when Rails is listening only on:

```text
127.0.0.1:3000
```

instead of:

```text
0.0.0.0:3000
```

### Correct Way

Inside `docker-compose.yml`, configure:

```yaml
command: >
  bash -c "
  rm -f tmp/pids/server.pid &&
  bundle exec rails server -b 0.0.0.0
  "
```

Then rebuild:

```bash
docker-compose down
docker-compose up --build -d
```

The application should now be available at:

```text
http://localhost:3000
```

---

# Verify Rails Server

View logs:

```bash
docker-compose logs -f app
```

You should see:

```text
Listening on tcp://0.0.0.0:3000
```

**NOT**

```text
Listening on http://127.0.0.1:3000
```

---

# Notes

* Uses PostgreSQL 17.
* Uses Redis 8.
* Tested with Docker Compose v1 (`docker-compose` command).
* If `docker compose` is unavailable, use:

```bash
docker-compose
```

instead.

---

This is the complete Docker-based setup and workflow used during development and testing of the Email Context API project.
