data "aws_instances" "web-server-instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.web-server-auto-scaling-grp.name
  }

  instance_state_names = ["running"]
}