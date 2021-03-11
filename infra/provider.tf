provider "google" {
  credentials = file("~/gcloud/${var.project_id}.json")
  project     = var.project_id
  region      = var.region
}