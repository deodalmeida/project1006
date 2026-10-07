# Traffic model:
#   Internet --80--> ALB SG --8000--> App SG --5432--> DB SG
#
# Tiers reference each other's security groups instead of CIDRs, so only
# members of the previous tier can connect, not anything else in the VPC.
# There is deliberately no port 22 rule anywhere: access is via SSM.
#
# Note: aws_security_group removes AWS's default allow-all egress rule, so
# every egress path below is explicit.

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public ALB: HTTP in from allowed CIDRs, app port out to app tier"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests and health checks to app tier"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app.id
}

# ---------------------------------------------------------------------------
# Application tier
# ---------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "App instances: app port from ALB only, no SSH"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from ALB only"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

# HTTPS out via NAT: dnf/pip during bootstrap, plus SSM and Secrets Manager APIs.
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS to AWS APIs and package repositories"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "PostgreSQL to DB tier"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

# ---------------------------------------------------------------------------
# Database tier
# ---------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "RDS PostgreSQL: 5432 from app tier only"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from app tier only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
}
# No egress rules: the database never initiates connections.
