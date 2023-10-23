locals {
  common_tags = {
    owner = "PSP"
  }
}

variable "WebServerPublicKey" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObVw33R38uXc+EDbCsvjOCukx5qdAWVxBftFMpJ3LZo parshuram.patil@outlook.in"
  description = "Public configured for Web Server"
}