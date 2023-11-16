output "WebServerUrl" {
  value = "www.${var.SubDomainName}.${data.aws_route53_zone.parent-zone.name}"
}