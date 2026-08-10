# Specz.co V2 — FastAPI Backend API

Production-ready FastAPI backend for Specz.co V2 providing cloud synchronization, authentication, Razorpay payments, server entitlements, AI/OCR services, and S3 storage integration.

## Quick Start (Local Development)

1. Create a Python 3.11 virtual environment and install dependencies:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt aiosqlite
```

2. Copy environment file:
```bash
cp .env.example .env
```

3. Run API server:
```bash
uvicorn app.main:app --reload --port 8000
```

4. Open Swagger documentation:
Visit `http://localhost:8000/docs` in your browser.

## Running Tests
```bash
pytest tests/
```

## Docker Deployment
```bash
docker compose up --build -d
```
