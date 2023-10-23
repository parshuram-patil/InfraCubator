resource "aws_vpc" "WebServerVPC" {
  cidr_block = var.WebServerVpcCidrBlock
  tags =  merge(local.common_tags, {
    Name = "web-server-vpc"
  })
}

data "aws_availability_zones" "AvailableZones" {
  state = "available"
}

resource "aws_subnet" "WebServerPublicSubnet" {
  vpc_id     = aws_vpc.WebServerVPC.id
  cidr_block = var.WebServerPublicSubnetCidrBlock
  availability_zone = data.aws_availability_zones.AvailableZones.names[0]
  map_public_ip_on_launch = true
  tags =  merge(local.common_tags, {
    Name = "web-server-public-subnet"
  })
}

resource "aws_internet_gateway" "WebServerInternetGateway" {
  vpc_id = aws_vpc.WebServerVPC.id
  tags =  merge(local.common_tags, {
    Name = "web-server-ig"
  })
}

resource "aws_route_table" "WebServerPublicRouteTable" {
  vpc_id = aws_vpc.WebServerVPC.id
  route {
    cidr_block = var.AnyIpCidrBlock
    gateway_id = aws_internet_gateway.WebServerInternetGateway.id
  }
  tags =  merge(local.common_tags, {
    Name = "web-server-route-table"
  })
}

resource "aws_route_table_association" "WebServerRouteAssociation" {
  subnet_id = aws_subnet.WebServerPublicSubnet.id
  route_table_id = aws_route_table.WebServerPublicRouteTable.id
}

resource "aws_key_pair" "WebServerRouteKeyPair" {
  key_name   = "WebServerRouteKeyPair"
  public_key = var.WebServerPublicKey
  tags =  merge(local.common_tags, {
    Name = "web-server-key-pair"
  })
}

resource "aws_instance" "WebServer" {
  ami           = var.WebServerAmiId
  instance_type = var.WebServerInstanceType
  subnet_id     = aws_subnet.WebServerPublicSubnet.id
  key_name      = aws_key_pair.WebServerRouteKeyPair.key_name
  vpc_security_group_ids = [aws_security_group.HttpOnlySecurityGroup.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Server provisioned by Terraform</h1>" > /var/www/html/index.html
              EOF
  tags =  merge(local.common_tags, {
    Name = "web-server"
  })
}

resource "aws_security_group" "HttpOnlySecurityGroup" {
  name        = "http-only-security-group"
  description = "Security group that allows incoming HTTP traffic on port 80"

  vpc_id = aws_vpc.WebServerVPC.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.AnyIpCidrBlock]
  }
}