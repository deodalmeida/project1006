# Non-secret values only. The DB password is never output; only the ARN of
# the secret that holds it, which is useless without IAM permission to read it.

output "application_url" {
  description = "Public URL of the application."
  value       = "http://${aws_lb.app.dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "rds_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.main.identifier
}

output "rds_endpoint" {
  description = "RDS hostname (private; reachable only inside the VPC)."
  value       = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "ARN of the AWS-managed Secrets Manager secret holding the DB master credentials."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
