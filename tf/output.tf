output "WebServerUrl" {
  value = "www.${var.SubDomainName}.${var.DomainName}"
}