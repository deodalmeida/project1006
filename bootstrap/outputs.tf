output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "aws_region" {
  description = "AWS Region of the state bucket."
  value       = var.aws_region
}

output "github_plan_role_arn" {
  description = "Set as GitHub repository variable AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.github_plan.arn
}

output "github_apply_role_arn" {
  description = "Set as GitHub repository variable AWS_APPLY_ROLE_ARN."
  value       = aws_iam_role.github_apply.arn
}
