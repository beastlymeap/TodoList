# Cloud Deployment Practice — Todo App

A minimal full-stack todo app deployed to **two Cloud Run services** with **IAM-authenticated service-to-service calls**, provisioned by **Terraform**, built and deployed by **Cloud Build** on every push to `main`.

```
Browser ──► Frontend Cloud Run (Python: static React + ID-token proxy)
                         │  Authorization: Bearer <ID token>
                         ▼
              API Cloud Run (Flask, in-memory todos, no public access)
```

## Repo layout

| Path | What lives there |
|---|---|
| `api/` | Flask REST API + Dockerfile |
| `frontend/app/` | React (Vite) source |
| `frontend/server/` | Static-file + auth-proxy Flask server |
| `frontend/Dockerfile` | Multi-stage: builds React, packages into Python runtime |
| `infra/` | Terraform: APIs, Artifact Registry, service accounts, Cloud Run, Cloud Build trigger |
| `cloudbuild.yaml` | CI/CD pipeline executed by the Cloud Build trigger |

## Local development

### API

```powershell
cd api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

API runs on http://localhost:8080. Smoke test:

```powershell
curl http://localhost:8080/api/health
curl -X POST http://localhost:8080/api/todos -H "Content-Type: application/json" -d '{\"title\":\"buy milk\"}'
curl http://localhost:8080/api/todos
```

### Frontend (Vite dev server with API proxy)

```powershell
cd frontend\app
npm install
npm run dev
```

Open the URL Vite prints (usually http://localhost:5173). `/api/*` is proxied to `http://localhost:8080` via `vite.config.js`, so the dev server skips the auth proxy entirely — convenient for iterating on UI.

## One-time GCP bootstrap

1. **Create / pick a GCP project**; record the project ID. Enable billing on it.
2. **Install and authenticate tools** (locally):
   ```powershell
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project <PROJECT_ID>
   ```
3. **Connect the GitHub repo to Cloud Build** via the GCP Console
   (`Cloud Build → Triggers → Manage repositories → Connect repository`).
   Terraform's `google_cloudbuild_trigger` requires the repo connection to exist already.
4. **Configure Terraform variables**:
   ```powershell
   cd infra
   Copy-Item terraform.tfvars.example terraform.tfvars
   notepad terraform.tfvars  # fill in project_id, github_owner, github_repo
   ```
5. **Apply infra**:
   ```powershell
   terraform init
   terraform plan
   terraform apply
   ```
   Outputs include `frontend_url` (public) and `api_url` (IAM-locked).

## Deploy

```powershell
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/<owner>/<repo>.git
git push -u origin main
```

The Cloud Build trigger fires on the push: it builds the API and frontend images, pushes them to Artifact Registry, and runs `gcloud run deploy` for both services. Watch the build in the GCP Console under **Cloud Build → History**.

## Verify deployment

Open `frontend_url` from the Terraform output in a browser — add, toggle, and delete todos to confirm round-trips through the auth proxy.

Confirm IAM auth is enforced on the API:

```powershell
# Through the frontend (proxy injects ID token) — should succeed:
curl <frontend_url>/api/todos

# Hitting the API directly without a token — should be 403 Forbidden:
curl <api_url>/api/todos

# Hitting the API through gcloud's authenticated proxy — should succeed.
# Service name defaults to "todo-api" (see infra/variables.tf), region to "us-central1":
gcloud run services proxy todo-api --port=9090 --region=us-central1
# then in another shell:
curl http://localhost:9090/api/todos
```

## Notes & limitations

- **Storage is in-memory and per-instance.** Cloud Run can run multiple instances and recycles them between requests; todos can disappear at any time. This is intentional for the first pass.
- **Cloud Run service images are placeholders in Terraform.** First `terraform apply` deploys `hello-world` containers; the first Cloud Build run replaces them with real images. The `lifecycle.ignore_changes` block prevents Terraform from reverting them.
- **Local proxy testing is impractical** — the auth proxy needs `gcloud auth application-default login` credentials *and* the calling identity must have `roles/run.invoker` on the API. Easier to test the proxy logic by deploying.

## Tear down

```powershell
cd infra
terraform destroy
```

Cloud Build trigger, Cloud Run services, service accounts, Artifact Registry repo, and API enablements are removed. Container images stored in Artifact Registry are removed with the repo.
