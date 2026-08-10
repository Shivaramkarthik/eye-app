# SPECZ.CO V2 — ARCHITECTURE SPECIFICATION

## Overview
Specz.co is a local-first digital eye-care companion built with Flutter 3.x, Dart 3.x, Material 3, and SQLite (`sqflite`), connected to a production FastAPI backend (`api.specz.co`) with PostgreSQL 15, Redis, S3 object storage, Razorpay payment verification, and offline-first cloud synchronization.

---

## Architecture Diagram

```text
                  SPECZ.CO FLUTTER APPLICATION
                               │
       ┌───────────────────────┴───────────────────────┐
       │                                               │
   OFFLINE                                           ONLINE
       │                                               │
       ▼                                               ▼
 local SQLite                                   FastAPI API Server
 (Local Source of Truth)                        (api.specz.co)
       │                                               │
       │                                               ▼
       └────────────── Sync Queue Engine ────────── PostgreSQL 15
```

---

## Component Responsibilities

```text
eye app/
├── backend/                       # Production FastAPI Cloud Infrastructure
│   ├── app/
│   │   ├── main.py                # FastAPI Application & Global Handlers
│   │   ├── api/v1/                # Endpoint Routers (Auth, Profiles, Sync, AI, Webhooks)
│   │   ├── core/                  # Config, Security & JWT Engine
│   │   ├── database/              # Async & Sync SQLAlchemy Engine
│   │   ├── models/                # PostgreSQL ORM Entities
│   │   ├── schemas/               # Pydantic Request/Response DTOs
│   │   └── services/              # Auth, Sync, Razorpay, AI, S3 Services
│   ├── migrations/                # Alembic Database Migrations
│   ├── tests/                     # Pytest Integration Suite
│   ├── Dockerfile                 # Multi-Stage Production Container Build
│   └── docker-compose.yml         # Dev/Staging Infrastructure Setup
│
├── lib/                           # Flutter Application
│   ├── core/
│   │   └── config/backend_config.dart # Dev / Staging / Prod Base URLs
│   ├── data/
│   │   ├── local/
│   │   │   ├── database_service.dart  # SQLite Database Service
│   │   │   ├── sync_queue.dart        # Offline Sync Queue Engine
│   │   │   └── dao/                   # Local DAOs
│   │   ├── remote/                    # Dio HTTP API Clients
│   │   │   ├── api_client.dart        # Dio Client with JWT Refresh Interceptor
│   │   │   ├── auth_api.dart
│   │   │   ├── profile_api.dart
│   │   │   ├── prescription_api.dart
│   │   │   ├── medication_api.dart
│   │   │   ├── sync_api.dart
│   │   │   ├── subscription_api.dart
│   │   │   └── ai_api.dart
│   │   └── repositories/             # Offline-First Repository Pattern
```

---

## Core Architecture Principles
1. **Offline-First SQLite**: Local SQLite remains the primary source of truth. All reads and writes occur locally first.
2. **Asynchronous Sync Queue**: Operations are enqueued in SQLite `sync_queue` table and flushed to `/api/v1/sync` when internet is restored.
3. **Server-Authoritative Entitlements**: Razorpay subscriptions and profile capacity limits (1 Free / 5 Plus) are strictly enforced by FastAPI server.
4. **Isolated AI & Payment Keys**: All secrets are stored exclusively on backend `.env`.
5. **Medical Data Nuances**: Cylinder power NULL is distinguished from 0.00. OCR output requires human confirmation prior to database save.
