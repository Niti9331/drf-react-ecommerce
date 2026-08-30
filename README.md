# Proshop — Dockerized 3-Tier E-Commerce Deployment

A public, non-Dockerized Django REST Framework + React + PostgreSQL e-commerce app, forked and containerized from scratch, then deployed to AWS EC2 with Docker Compose.

Forked from [`VaibhavArora314/drf-react-ecommerce`](https://github.com/VaibhavArora314/drf-react-ecommerce) → this repo.

## Stack

| Layer | Technology |
|---|---|
| Frontend | React.js, served via Nginx (multi-stage build) |
| Backend | Django + Django REST Framework |
| Database | PostgreSQL 15 |
| Orchestration | Docker Compose |
| Auth | JWT (`djangorestframework-simplejwt`) + Google OAuth (upstream) |
| Cloud | AWS EC2 — Ubuntu 22.04, t3.small, 12 GB storage |

## Architecture

Three containers on one custom Docker bridge network (`ecommerce_network`):

```
                 ┌────────────────────── EC2 (t3.small) ──────────────────────┐
                 │        ┌──────────── ecommerce_network ───────────┐        │
   internet ──── │ :3000 →│  frontend (Nginx)  ──/api /auth /admin──▶│        │
                 │        │        │                                 │        │
   internet ──── │ :8000 →│        ▼                                 │        │
                 │        │  backend (Django)  ──db:5432────────────▶│  db    │
                 │        │                                          │ (PG15) │
                 │        └──────────────────────────────────────────┴────────┘
                 │                                          postgres_data (volume)
                 └──────────────────────────────────────────────────────────────┘
```

- Frontend → Backend: Nginx reverse-proxies `/api/`, `/auth/`, `/admin/` to `http://backend:8080`
- Backend → Database: Django connects via the Compose service name `db:5432` (never `localhost`)
- PostgreSQL is **not** exposed on the EC2 public interface — reachable only from the backend, over the internal network, gated by a healthcheck

## Ports

| Service | Container port | EC2 port |
|---|---|---|
| Frontend / Nginx | 80 | 3000 (public) |
| Backend / Django | 8080 | 8000 (public) |
| PostgreSQL | 5432 | not exposed (internal only) |

## Running locally

```bash
git clone https://github.com/Niti9331/drf-react-ecommerce.git
cd drf-react-ecommerce

# recreate .env (gitignored) — see .env.example
docker compose up --build

# first run only
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser
```

- Frontend: `http://localhost:3000`
- Backend / Admin: `http://localhost:8000/admin`

## Persistence

PostgreSQL data lives in the named volume `postgres_data`, mounted at `/var/lib/postgresql/data`. Verified by seeding data through the admin panel, running `docker compose down` → `docker compose up --build`, and confirming the data survived — both locally and on EC2.

## Security notes

- Secrets (`SECRET_KEY`, `DATABASE_URL`) live only in `.env`, gitignored, injected via `env_file` — never baked into the image
- `.env`, `venv/`, `__pycache__/`, `*.pyc`, `db.sqlite3` are all gitignored
- Only SSH (22), frontend (3000), and backend (8000) are open on the EC2 security group — port 5432 stays closed by design

## Notable fixes along the way

- Reordered the backend Dockerfile (`COPY requirements.txt` → `RUN pip install` → `COPY . .`) for correct build context and better layer caching
- Upgraded `psycopg2-binary` to resolve a SCRAM-SHA-256 auth mismatch with Postgres 15
- Replaced `host.docker.internal` in `nginx.conf` with the Compose service name `backend`, which resolves via Docker's built-in DNS on any platform (Linux/EC2 included)
- Standardized `docker-compose.yml` on long-form `depends_on` with `service_healthy` conditions

## Full write-up

See [`Proshop_Docker_Deployment_Report_Enhanced.html`](./Proshop_Docker_Deployment_Report_Enhanced.html) for the full architecture breakdown, troubleshooting log, and deployment screenshots.
