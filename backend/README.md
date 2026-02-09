# FreshReminder Backend (scaffold)

This folder contains a minimal Flask scaffold implementing stubbed endpoints for the FreshReminder project. It is intended as a starting point derived from `main_battleplan.md`.

Files added:
- `app.py` - Flask application factory and entrypoint
- `auth.py` - Auth blueprint with stub endpoints (`/auth/*`)
- `products.py` - Product blueprint with in-memory store (`/products/*`)
- `cart.py` - Cart blueprint with a minimal in-memory cart (`/cart/*`)
- `schema.sql` - Initial PostgreSQL schema (from the battleplan)
- `requirements.txt` - Python dependencies for the scaffold
- `../.env.example` - Example env file at repo root

Quick start (Linux):

1. Create and activate a virtualenv

```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Install requirements

```bash
pip install -r backend/requirements.txt
```

3. Run the app

```bash
python backend/app.py
```

The app will listen on `http://0.0.0.0:5000/` by default. Endpoints are intentionally minimal — use this scaffold to implement the services described in `main_battleplan.md`.
