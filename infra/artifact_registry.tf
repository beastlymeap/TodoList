resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"
  description   = "Container images for the todo app"

  depends_on = [google_project_service.apis]
}
