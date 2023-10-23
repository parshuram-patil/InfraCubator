locals {
  common_tags = {
    owner = "PSP"
  }
}

variable "region" {
  default = "eu-central-1"
  description = "Default AWS region"
}

variable "WebServerPublicKey" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObVw33R38uXc+EDbCsvjOCukx5qdAWVxBftFMpJ3LZo parshuram.patil@outlook.in"
  description = "Public configured for Web Server"
}

variable "WebServerAmiId" {
  default = "ami-0fb820135757d28fd"
  description = "AMI ID used to create WebServer"
}

variable "WebServerInstanceType" {
  default = "t2.micro"
  description = "WebServer Instance Type"
}

variable "AnyIpCidrBlock" {
  default = "0.0.0.0/0"
  description = "CIDR block that allows all IPs"
}

variable "WebServerVpcCidrBlock" {
  default = "10.0.0.0/16"
  description = "CIDR block that reserves 65,536 from 10.0.0.0 to 10.0.255.255"
}

variable "WebServerPublicSubnetCidrBlock" {
  default = "10.0.1.0/24"
  description = "CIDR block that reserves 256 from 10.0.1.0 to 10.0.1.255"
}