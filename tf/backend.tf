terraform {
  backend "s3" {
    bucket  = "eu-tf-states"
    key     = "state/web-server.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
