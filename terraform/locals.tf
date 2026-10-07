locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Two AZs for the base lab.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Subnet plan (VPC 10.20.0.0/16, every subnet a /24, one per AZ):
  #
  #   tier         AZ a            AZ b            internet route
  #   public       10.20.0.0/24    10.20.1.0/24    IGW
  #   private-app  10.20.10.0/24   10.20.11.0/24   NAT (outbound only)
  #   private-db   10.20.20.0/24   10.20.21.0/24   none
  #
  # Gaps between tiers leave room to add AZs without renumbering.
  public_subnet_cidrs = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]
  app_subnet_cidrs    = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, 10 + i)]
  db_subnet_cidrs     = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, 20 + i)]
}
