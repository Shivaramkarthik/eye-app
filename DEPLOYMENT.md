# SPECZ.CO V2 — PRODUCTION DEPLOYMENT & INFRASTRUCTURE MANUAL

This document provides a production-grade step-by-step deployment guide for the **Specz.co V2 FastAPI Cloud Sync Backend** and associated infrastructure.

---

## 1. PRODUCTION SYSTEM ARCHITECTURE

```text
                               INTERNET
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   DNS Record    │
                         │  api.specz.co   │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  Nginx / Caddy  │
                         │  (HTTPS / SSL)  │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   FastAPI API   │
                         │ (Docker / Gunicorn)
                         └────────┬────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
   PostgreSQL 15          Redis (Task Queue)       Private S3 Storage
 (Cloud Managed DB)          (Task Engine)        (Encrypted Medical Docs)
```


---

## 2. PRE-DEPLOYMENT PREREQUISITES

1. **Domain Name**: Fully qualified domain name pointing to your production server (e.g. `api.specz.co` and `staging-api.specz.co`).
2. **Server Infrastructure**: Linux VM (Ubuntu 22.04 LTS / Debian 12) with Docker 24.0+ and Docker Compose installed.
3. **Database**: PostgreSQL 15+ database instance (e.g., AWS RDS PostgreSQL, DigitalOcean Managed Database, or self-hosted container).
4. **Object Storage**: S3-compatible bucket with private access permissions (AWS S3, Cloudflare R2, MinIO, or DigitalOcean Spaces).
5. **Razorpay Account**: Verified Razorpay merchant account with Live Key ID, Secret, and Webhook Secret configured.

---

## 3. STEP-BY-STEP BACKEND DEPLOYMENT

### Step 3.1: Server Environment Provisioning
Clone repository and navigate to `backend/`:
```bash
git clone https://github.com/specz-co/eye-app.git
cd "eye app/backend"
```

### Step 3.2: Environment Configuration
Copy `.env.example` to `.env` and fill in production secrets:
```bash
cp .env.example .env
nano .env
```
Ensure the following variables are configured:
```ini
ENVIRONMENT=production
DEBUG=False
API_V1_STR=/api/v1
PROJECT_NAME="Specz.co V2 API"

# Database
DATABASE_URL=postgresql+asyncpg://specz_prod_user:SECURE_PASSWORD@postgres.internal:5432/specz_prod_db
SYNC_DATABASE_URL=postgresql://specz_prod_user:SECURE_PASSWORD@postgres.internal:5432/specz_prod_db

# JWT Security Secrets (Minimum 32 random bytes)
JWT_SECRET=GENERATED_SECURE_JWT_SECRET_32_BYTES
REFRESH_TOKEN_SECRET=GENERATED_SECURE_REFRESH_SECRET_32_BYTES

# Razorpay Payments
RAZORPAY_KEY_ID=rzp_live_XXXXXXXXXXXXXX
RAZORPAY_KEY_SECRET=LIVE_RAZORPAY_SECRET_KEY
RAZORPAY_WEBHOOK_SECRET=LIVE_RAZORPAY_WEBHOOK_SECRET

# S3 Private Object Storage
S3_ENDPOINT=https://s3.us-east-1.amazonaws.com
S3_BUCKET=specz-medical-storage-prod
S3_ACCESS_KEY=AWS_ACCESS_KEY_ID
S3_SECRET_KEY=AWS_SECRET_ACCESS_KEY
```

### Step 3.3: Database Migrations
Execute Alembic database schema migrations:
```bash
docker compose run --rm api alembic upgrade head
```

### Step 3.4: Container Stack Launch
Launch FastAPI API service and Redis task queue:
```bash
docker compose -f docker-compose.yml up -d --build
```

---

## 4. REVERSE PROXY & HTTPS SETUP (NGINX + LET'S ENCRYPT)

Install Nginx and Certbot:
```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

Configure `/etc/nginx/sites-available/api.specz.co`:
```nginx
server {
    server_name api.specz.co;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site and request SSL Certificate:
```bash
sudo ln -s /etc/nginx/sites-available/api.specz.co /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d api.specz.co
```

---

## 5. RAZORPAY WEBHOOK CONFIGURATION

1. Log in to **Razorpay Dashboard** -> **Settings** -> **Webhooks**.
2. Add Webhook URL: `https://api.specz.co/api/v1/webhooks/razorpay`.
3. Secret: Enter `RAZORPAY_WEBHOOK_SECRET` matching your `.env` value.
4. Active Events: Select `payment.captured`, `order.paid`, `subscription.activated`.

---

## 6. BACKUP & RESTORE PROCEDURES

### Database Automated Daily Backup
Create script `/opt/scripts/backup_db.sh`:
```bash
#!/bin/bash
BACKUP_DIR="/var/backups/specz"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p $BACKUP_DIR

docker exec -t specz_db pg_dump -U specz_prod_user specz_prod_db | gzip > "$BACKUP_DIR/specz_db_$TIMESTAMP.sql.gz"
find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +30 -delete
```

### Database Restore Procedure
To restore from a backup file:
```bash
gunzip -c /var/backups/specz/specz_db_TIMESTAMP.sql.gz | docker exec -i specz_db psql -U specz_prod_user -d specz_prod_db
```

---

## 7. MONITORING & HEALTH CHECKS

* **Liveness Probe**: `GET https://api.specz.co/health`
* **Readiness Probe**: `GET https://api.specz.co/health/ready`
* **App Logs**: `docker compose logs -f api`

---

## 8. ROLLBACK STRATEGY

If a deployment fails, roll back to the previous Docker image and migration version:
```bash
# Roll back database migration by 1 revision if safe
docker compose run --rm api alembic downgrade -1

# Redeploy previous stable tag
git checkout main~1
docker compose up -d --build
```
