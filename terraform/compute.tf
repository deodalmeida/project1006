# Application delivery: the provided app/ files are embedded (base64) into the
# user data at plan time. This keeps the lab self-contained (no artifact bucket
# or extra IAM). Changing app/ creates a new launch template version, and the
# ASG instance refresh below rolls instances onto it.

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  # No key_name: there is no SSH access. Use Session Manager.

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
    delete_on_termination       = true
  }

  # IMDSv2 only.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = data.aws_ami.al2023.root_device_name

    ebs {
      volume_size           = 10
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh.tftpl", {
    aws_region       = var.aws_region
    app_port         = var.app_port
    db_host          = aws_db_instance.main.address
    db_name          = var.db_name
    db_secret_arn    = aws_db_instance.main.master_user_secret[0].secret_arn
    app_py_b64       = filebase64("${path.module}/../app/app.py")
    requirements_b64 = filebase64("${path.module}/../app/requirements.txt")
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name_prefix}-app" }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${local.name_prefix}-app" }
  }

  # The instance role must be able to read the secret before the app starts.
  depends_on = [aws_iam_role_policy.read_db_secret]
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-app-asg"
  vpc_zone_identifier = aws_subnet.app[*].id
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size

  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  lifecycle {
    precondition {
      condition     = var.asg_min_size <= var.asg_desired_capacity && var.asg_desired_capacity <= var.asg_max_size
      error_message = "ASG sizes must satisfy min <= desired <= max."
    }
  }
}
