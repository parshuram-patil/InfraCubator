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

resource "aws_route_table" "WebServerPublicRouteTable" {
  vpc_id = aws_vpc.WebServerVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.WebServerInternetGateway.id
  }
}

resource "aws_route_table_association" "WebServerRouteAssociation" {
  subnet_id = aws_subnet.WebServerPublicSubnet.id
  route_table_id = aws_route_table.WebServerPublicRouteTable.id
}

resource "aws_key_pair" "WebServerRouteKeyPair" {
  key_name   = "WebServerRouteKeyPair"
  public_key = var.WebServerPublicKey
}