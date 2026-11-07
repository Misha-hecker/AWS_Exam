# Auto Scaling Group: min 1 / max 2 / desired 1, health check через ELB
resource "aws_autoscaling_group" "this" {
  name                      = "${var.project_name}-asg"
  vpc_zone_identifier       = local.public_subnet_ids
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [aws_lb_target_group.this.arn]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "ToDoAI"
    propagate_at_launch = true
  }
}
