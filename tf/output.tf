output "WebServerPubicId" {
  value = aws_instance.WebServer.public_ip
}