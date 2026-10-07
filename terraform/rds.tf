resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnets"
  description = "Private DB subnets for ${local.name_prefix}"
  subnet_ids  = aws_subnet.db[*].id

  tags = { Name = "${local.name_prefix}-db-subnets" }
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  # AWS generates the password and stores it in Secrets Manager; it never
  # appears in Terraform code, variables, state, or outputs.
  manage_master_user_password = true

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  apply_immediately          = true

  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${local.name_prefix}-postgres-final"

  tags = { Name = "${local.name_prefix}-postgres" }
}
