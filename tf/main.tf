resource "aws_vpc" "WebServerVPC" {
  cidr_block = "10.0.0.0/16"
  tags =  merge(local.common_tags, {
    Name = "WebServerVPC"
  })
}