variable "aws_region" {
  description = "AWS Region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name, used as a prefix for resource names."
  type        = string
  default     = "project1006"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "project_name must be lowercase letters, digits or hyphens (2-21 chars) so it fits ALB/target group name limits."
  }
}

variable "environment" {
  description = "Environment name, e.g. dev, staging, prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Subnets are carved out of it as /24s (see locals.tf)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "vpc_cidr must be a valid CIDR of /16 or larger."
  }
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of application instances."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of application instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of application instances."
  type        = number
  default     = 4
}

variable "app_port" {
  description = "Port the Flask/gunicorn application listens on."
  type        = number
  default     = 8000
}

variable "db_instance_class" {
  description = "RDS instance class. db.t4g.micro is not orderable for PostgreSQL in this account/Region, so db.t3.micro is used."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL major version. A major-only value lets AWS pick the latest minor."
  type        = string
  default     = "17"
}

variable "db_name" {
  description = "Initial database name. Must match DB_NAME expected by the app."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username. The password is generated and stored by AWS in Secrets Manager."
  type        = string
  default     = "appadmin"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS, in GiB."
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Deploy RDS Multi-AZ. false keeps the lab cheaper (stretch goal: true)."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection. Off for the lab so terraform destroy works."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. true for the lab; false in production."
  type        = bool
  default     = true
}
