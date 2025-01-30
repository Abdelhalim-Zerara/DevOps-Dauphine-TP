terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.10"
    }
     kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "gcs" {
    bucket = "tp6-zerara-bucket"
  }

  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
