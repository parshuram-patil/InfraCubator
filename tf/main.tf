resource "aws_vpc" "WebServerVPC" {
  cidr_block = "10.0.0.0/16"
  tags =  merge(local.common_tags, {
    Name = "WebServerVPC"
  })
}

data "aws_availability_zones" "AvailableZones" {
  state = "available"
}

resource "aws_subnet" "WebServerPublicSubnet" {
  vpc_id     = aws_vpc.WebServerVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.AvailableZones.names[0]
  map_public_ip_on_launch = true
  tags =  merge(local.common_tags, {
    Name = "WebServerPublicSubnet"
  })
}

resource "aws_internet_gateway" "WebServerInternetGateway" {
  vpc_id = aws_vpc.WebServerVPC.id
}