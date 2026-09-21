# VenueCore SaaS (POC) 🏢

VenueCore is an enterprise-grade, multi-tenant operations platform designed for restaurants, beach clubs, and hospitality venues. It unifies daily operations into a single ecosystem by combining a cross-platform **Flutter** application for owners and staff with a robust **NestJS** backend API, **PostgreSQL** persistence, and real-time **Socket.IO** event synchronization.

---

## 🏗️ Architecture & Core Capabilities

### 1. Multi-Tenant Infrastructure & Security
* **Tenant Isolation:** Strict logical isolation at the service boundary. Authenticated services derive the `tenantId` cryptographically from the JWT rather than trusting client-supplied identifiers.
* **Role-Based Access Control (RBAC):** Granular permissions distributed across `OWNER`, `STAFF`, and `CLIENT` roles.
* **Secure Authentication:** Passport JWT strategies with bcrypt password hashing and global DTO validation (class-validator) with strict whitelisting.

### 2. Real-Time Operations (Event-Driven)
* **Socket.IO Integration:** Live broadcasting for order status updates, checklist completions, and real-time POS (Point of Sale) synchronization across multiple active terminals.
* **Interactive Floor Plans:** Dynamic, draggable vector mapping for tables and bookable resources, synchronized instantly across staff devices.

### 3. Venue & HR Management
* **Operations CRM:** Employee records, shift planning, compliance tracking, and customer loyalty management.
* **Dynamic Checklists:** Role-assigned daily routines (HACCP, opening/closing) with boolean, numeric, and photographic validation payloads.

---

## 🛠️ Technology Stack

| Layer | Technology |
| --- | --- |
| **Client Application** | Flutter/Dart, Material 3, Riverpod (State Management), GoRouter |
| **Client Networking** | Dio (with JWT Interceptors), WebSockets |
| **Backend API** | NestJS 11, TypeScript, Express |
| **Database & ORM** | PostgreSQL 15, Prisma 5 (Schema migrations & seeding) |
| **Infrastructure** | Docker, Docker Compose, pgAdmin |

---

## 📂 Repository Structure

```text
venuecore_saas/
├── backend/                  # NestJS API, Prisma schema, migrations, and seed data
│   ├── src/                  # Domain modules (Auth, Booking, Order, etc.)
│   └── prisma/               # Database schemas and migration history
├── frontend/                 # Flutter application (Mobile, Desktop, Web)
│   ├── lib/core/             # API clients, routing, and shared utilities
│   └── lib/features/         # Feature-sliced modules (Data, Domain, Presentation)
└── docker-compose.yml        # Local infrastructure definition (PostgreSQL)
