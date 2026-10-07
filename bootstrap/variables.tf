variable "aws_region" {
  description = "AWS Region where the Terraform state bucket lives."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used for tagging."
  type        = string
  default     = "project1006"
}

variable "state_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores Terraform state."
  type        = string
  default     = "ayele-s3-bucket"
}

variable "state_key_prefix" {
  description = "Top-level prefix of the state keys in the bucket (CI may write lockfiles under it)."
  type        = string
  default     = "job-readiness"
}


variable "github_apply_environment" {
  description = "GitHub Environment (with required reviewers) whose jobs may assume the apply role."
  type        = string
  default     = "production"
}

variable "app_environment" {
  description = "Environment name of the main stack; scopes the IAM resources the apply role may manage."
  type        = string
  default     = "dev"
}

variable "github_oidc_sub_prefix" {
  description = "Prefix of the OIDC 'sub' claim GitHub issues for the repository (immutable format: repo:<owner>@<owner_id>/<repo>@<repo_id>)."
  type        = string
  default     = "repo:deodalmeida@264557802/project1006@1408087175"
}
