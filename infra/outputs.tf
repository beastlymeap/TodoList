output "api_url" {
  value       = google_cloud_run_v2_service.api.uri
  description = "Internal API URL. Requires IAM auth (Authorization: Bearer <id-token>)."
}

output "frontend_url" {
  value       = google_cloud_run_v2_service.frontend.uri
  description = "Public frontend URL — open this in a browser."
}

output "artifact_registry" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}"
  description = "Artifact Registry path prefix for the app's images."
}
