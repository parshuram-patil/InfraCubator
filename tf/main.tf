resource "aws_vpc" "WebServerVPC" {
  cidr_block = var.WebServerVpcCidrBlock
  tags = merge(local.common_tags, {
    Name = "web-server-vpc"
  })
}

resource "aws_subnet" "WebServerPublicSubnet" {
  vpc_id                  = aws_vpc.WebServerVPC.id
  cidr_block              = var.WebServerPublicSubnetCidrBlock
  availability_zone       = data.aws_availability_zones.AvailableZones.names[0]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "web-server-public-subnet"
  })
}

resource "aws_internet_gateway" "WebServerInternetGateway" {
  vpc_id = aws_vpc.WebServerVPC.id
  tags = merge(local.common_tags, {
    Name = "web-server-ig"
  })
}

resource "aws_route_table" "WebServerPublicRouteTable" {
  vpc_id = aws_vpc.WebServerVPC.id
  route {
    cidr_block = var.AnyIpCidrBlock
    gateway_id = aws_internet_gateway.WebServerInternetGateway.id
  }
  tags = merge(local.common_tags, {
    Name = "web-server-route-table"
  })
}

resource "aws_route_table_association" "WebServerRouteAssociation" {
  subnet_id      = aws_subnet.WebServerPublicSubnet.id
  route_table_id = aws_route_table.WebServerPublicRouteTable.id
}

resource "tls_private_key" "WebServerKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "WebServerPrivateKey" {
  content         = tls_private_key.WebServerKey.private_key_pem
  filename        = "~/.ssh/ec2.pem"
  file_permission = "666"
}

resource "aws_key_pair" "WebServerKeyPair" {
  key_name   = "WebServerKeyPair"
  public_key = tls_private_key.WebServerKey.public_key_openssh
  tags = merge(local.common_tags, {
    Name = "web-server-key-pair"
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

  /*ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.AnyIpCidrBlock]
  }*/

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "http-only-security-group"
  })
}

/*resource "aws_instance" "WebServer" {
  ami           = var.WebServerAmiId
  instance_type = var.WebServerInstanceType
  subnet_id     = aws_subnet.WebServerPublicSubnet.id
  key_name      = aws_key_pair.WebServerKeyPair.key_name
  vpc_security_group_ids = [aws_security_group.HttpOnlySecurityGroup.id]
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "echo '<h1>Hello from Web Server provisioned by Terraform</h1>' | sudo tee /var/www/html/index.html"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"  # Replace with your SSH user
      private_key = tls_private_key.WebServerKey.private_key_pem
      host        = self.public_ip
    }
  }

  tags =  merge(local.common_tags, {
    Name = "web-server"
  })
}*/

resource "aws_launch_template" "web-server-launch-template" {
  name_prefix            = "web-server-"
  image_id               = var.WebServerAmiId
  instance_type          = var.WebServerInstanceType
  key_name               = aws_key_pair.WebServerKeyPair.key_name
  vpc_security_group_ids = [aws_security_group.HttpOnlySecurityGroup.id]
  user_data = base64encode(
    <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Hello from Web Server provisioned by Terraform</h1>" > /var/www/html/index.html
              EOF
  )

  tags = merge(local.common_tags, {
    Name = "web-server-launch-template"
  })
}

resource "aws_autoscaling_group" "web-server-auto-scaling-grp" {
  name_prefix         = "web-server-"
  max_size            = var.WebServerMaxSize
  min_size            = var.WebServerMinSize
  desired_capacity    = var.WebServerDesiredCapacity
  vpc_zone_identifier = [aws_subnet.WebServerPublicSubnet.id]

  launch_template {
    id      = aws_launch_template.web-server-launch-template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    propagate_at_launch = true
    key                 = "Name"
    value               = "web-server"
  }
}

resource "aws_autoscaling_policy" "web-server-scale-out-policy" {
  name                   = "web-server-scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web-server-auto-scaling-grp.name
}

resource "aws_autoscaling_policy" "web-server-scale-in-policy" {
  name                   = "web-server-scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web-server-auto-scaling-grp.name
}

resource "aws_cloudwatch_metric_alarm" "web-server-high-cpu-utilization" {
  alarm_name          = "web-server-high-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_autoscaling_policy.web-server-scale-out-policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "web-server-low-cpu-utilization" {
  alarm_name          = "web-server-low-cpu-utilization-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_actions       = [aws_autoscaling_policy.web-server-scale-in-policy.arn]
}

resource "aws_route53_zone" "web-server-domain" {
  name    = "${var.SubDomainName}.${data.aws_route53_zone.parent-zone.name}"
  comment = "Sub domain of ${data.aws_route53_zone.parent-zone.name}"
}

resource "aws_route53_record" "web-server-a-record" {
  name    = "www"
  type    = "A"
  zone_id = aws_route53_zone.web-server-domain.zone_id
  ttl     = "300"
  records = data.aws_instances.web-server-instances.public_ips
#  records = [data.aws_instances.web-server-instances.public_ips[0]]
}

resource "aws_route53_record" "web-server-ns-record" {
  name    = var.SubDomainName
  type    = "NS"
  zone_id = var.ParentDomainZoneId
  ttl     = "300"
  records = aws_route53_zone.web-server-domain.name_servers
}