# Autoscaling policy (пункт 3a завдання):
# target-tracking — тримає середнє завантаження CPU інстансів ASG на рівні 60%
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value       = var.cpu_target_value
    disable_scale_in   = false
  }
}
