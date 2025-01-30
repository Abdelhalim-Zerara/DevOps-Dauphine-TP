
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
   password = "password123"
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

resource "kubernetes_namespace" "wordpress" {
  metadata {
    name = "wordpress"
  }
}

# MySQL Secret
resource "kubernetes_secret" "mysql" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    "mysql-root-password" = base64encode(var.mysql_root_password)
    "mysql-user"          = base64encode(var.mysql_user)
    "mysql-password"      = base64encode(var.mysql_password)
    "mysql-database"      = base64encode(var.mysql_database)
  }
}

# MySQL Deployment
resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          image = "mysql:5.7"
          name  = "mysql"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-root-password"
              }
            }
          }

          env {
            name  = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-database"
              }
            }
          }

          env {
            name  = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-user"
              }
            }
          }

          env {
            name  = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-password"
              }
            }
          }

          port {
            container_port = 3306
          }

          volume_mount {
            mount_path = "/var/lib/mysql"
            name       = "mysql-persistent-storage"
          }
        }

        volume {
          name = "mysql-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
          }
        }
      }
    }
  }
}

# MySQL Service
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port     = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
}

# MySQL Persistent Volume Claim
resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name      = "mysql-pv-claim"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

# WordPress Deployment
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          image = "us-central1-docker.pkg.dev/iron-flash-376014/website-tools/custom-wordpress:latest"
          name  = "wordpress"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = kubernetes_service.mysql.metadata[0].name
          }

          env {
            name  = "WORDPRESS_DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-user"
              }
            }
          }

          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-password"
              }
            }
          }

          env {
            name  = "WORDPRESS_DB_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "mysql-database"
              }
            }
          }

          port {
            container_port = 80
          }

          volume_mount {
            mount_path = "/var/www/html"
            name       = "wordpress-persistent-storage"
          }
        }

        volume {
          name = "wordpress-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wordpress.metadata[0].name
          }
        }
      }
    }
  }
}

# WordPress Service
resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    selector = {
      app = "wordpress"
    }

    port {
      port     = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# WordPress Persistent Volume Claim
resource "kubernetes_persistent_volume_claim" "wordpress" {
  metadata {
    name      = "wp-pv-claim"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

output "wordpress_service_ip" {
  value = kubernetes_service.wordpress.status[0].load_balancer[0].ingress[0].ip
}