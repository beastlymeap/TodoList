resource "google_service_account" "api" {
  account_id   = "api-sa"
  display_name = "Runtime identity for todo-api Cloud Run service"
}

resource "google_service_account" "frontend" {
  account_id   = "frontend-sa"
  display_name = "Runtime identity for todo-frontend Cloud Run service"
}

resource "google_service_account" "cloudbuild_deployer" {
  account_id   = "cloudbuild-deployer-sa"
  display_name = "Cloud Build deployer for the todo app"
}

resource "google_project_iam_member" "deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild_deployer.email}"
}

resource "google_project_iam_member" "deployer_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_deployer.email}"
}

resource "google_project_iam_member" "deployer_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_deployer.email}"
}
