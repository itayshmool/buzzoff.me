# BuzzOff — Project Notes

## Domain

- **Primary domain: `buzzoff.me`**
- Backend API base URL: `https://buzzoff.me/api/` (proxied) or `https://buzzoff-api.onrender.com/`
- ALWAYS use `buzzoff.me` when referring to the project domain. Never guess other domains.

## Deployment

- **Website (buzzoff.me)**: Deployed via **GitHub Pages** from the `gh-pages` branch (root `/`). NOT from `main`.
  - To update the website: checkout `gh-pages`, update files at root, commit, push.
  - The `main` branch has website source under `website/` but that's not what gets served.
  - Custom domain: `buzzoff.me` (CNAME in `gh-pages` root)
  - HTTPS enforced, certificate auto-managed by GitHub.

- **Backend API (buzzoff-api.onrender.com)**: Deployed on Render from `main` branch.
  - Service ID: `srv-d6o8ltia214c73enbs9g`
  - Runtime: Python (uvicorn + FastAPI)
  - Persistent disk at `/data/packs` (1GB) for camera pack `.db` files.
  - If disk is wiped (redeploy), pack files are lost. Regenerate via: `POST /admin/api/jobs/run/generate_packs` (requires admin JWT).

## Key Paths

| What | Path |
|------|------|
| Flutter app | `app/` |
| Backend API | `backend/` |
| Admin dashboard | `admin/` |
| Website source (main) | `website/` |
| Store assets | `app/assets/store/` |
| App icon | `app/assets/icon/` |
| Feature specs | `FEATURES/` |

## Package Name

- Android: `me.buzzoff.app` (NOT `com.buzzoff.app`)

## Admin API

- Login: `POST /admin/api/auth/login` with `{username, password}` returns JWT
- Credentials configured via Render env vars `ADMIN_USERNAME`, `ADMIN_PASSWORD`
- Local dev credentials in `backend/.env`
