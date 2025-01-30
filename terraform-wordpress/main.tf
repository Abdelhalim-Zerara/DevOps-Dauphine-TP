
# Enable required APIs
resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "serviceusage" {
  service = "serviceusage.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager]
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
  depends_on = [google_project_service.serviceusage]
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  depends_on = [google_project_service.artifactregistry]
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
  depends_on = [google_project_service.sqladmin]
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
  depends_on = [google_project_service.cloudbuild]
}

data "google_iam_policy" "noauth" {
   binding {
      role = "roles/run.invoker"
      members = [
         "allUsers",
      ]
   }
}

resource "google_cloud_run_service" "default" {
  name     = "serveur-wordpress"
  location = var.region

  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/iron-flash-376014/website-tools/custom-wordpress:latest"
        ports {
          container_port = 80
        }
        env {
          name  = "WORDPRESS_DB_PASSWORD"
          value = "password123"
        }
      }

      }
    }
  

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = var.region
   project     = var.project_id
   service     = google_cloud_run_service.default.name

   policy_data = data.google_iam_policy.noauth.policy_data
}


resource "google_sql_user" "wordpress" {
   name     = "wordpress"
   instance = "main-instance"
   password = "ilovedevops"
}

data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
   name     = "gke-dauphine"
   location = "us-central1-a"
}

provider "kubernetes" {
   host                   = data.google_container_cluster.my_cluster.endpoint
   token                  = data.google_client_config.default.access_token
   cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
}