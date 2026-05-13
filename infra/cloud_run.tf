locals {
  # Cloud Run requires a valid image at create-time. Cloud Build replaces this on first deploy.
  placeholder_image = "us-docker.pkg.dev/cloudrun/container/hello"
}

resource "google_cloud_run_v2_service" "api" {
  name                = var.api_service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.api.email
    containers {
      image = local.placeholder_image
      ports {
        container_port = 8080
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service" "frontend" {
  name                = var.frontend_service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.frontend.email
    containers {
      image = local.placeholder_image
      ports {
        container_port = 8080
      }
      env {
        name  = "API_URL"
        value = google_cloud_run_v2_service.api.uri
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }

  depends_on = [google_project_service.apis]
}

# Frontend SA can invoke the API (this is the IAM-auth backbone).
resource "google_cloud_run_v2_service_iam_member" "frontend_invokes_api" {
  project  = google_cloud_run_v2_service.api.project
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.frontend.email}"
}

# The browser-facing frontend is public.
resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  project  = google_cloud_run_v2_service.frontend.project
  location = google_cloud_run_v2_service.frontend.location
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
