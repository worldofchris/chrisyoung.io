terraform {
  source = "."
}

locals {
  project_id = "chrisyoung-io"
}

inputs = {
  project_id = local.project_id
  region = "europe-west1"
}

remote_state {
  backend = "gcs"
  config = {
    bucket = "${local.project_id}-tfstate"
    prefix = "terraform/state"
    credentials = "${local.project_id}.json"
  }
}
