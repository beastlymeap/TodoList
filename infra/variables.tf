variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Region for all resources."
}

variable "github_owner" {
  type        = string
  description = "GitHub username or org that owns the repo."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

variable "repo_name" {
  type        = string
  default     = "todo-app"
  description = "Artifact Registry repository name."
}

variable "api_service_name" {
  type        = string
  default     = "todo-api"
  description = "Cloud Run service name for the API."
}

variable "frontend_service_name" {
  type        = string
  default     = "todo-frontend"
  description = "Cloud Run service name for the frontend."
}
