resource "google_cloudbuild_trigger" "main_push" {
  name            = "todo-app-main"
  location        = var.region
  service_account = google_service_account.cloudbuild_deployer.id
  filename        = "cloudbuild.yaml"

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    _REGION           = var.region
    _REPO             = var.repo_name
    _API_SERVICE      = var.api_service_name
    _FRONTEND_SERVICE = var.frontend_service_name
    _API_SA           = google_service_account.api.account_id
    _FRONTEND_SA      = google_service_account.frontend.account_id
  }

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.deployer_run_admin,
    google_project_iam_member.deployer_ar_writer,
    google_project_iam_member.deployer_sa_user,
    google_project_iam_member.deployer_logs_writer,
  ]
}
