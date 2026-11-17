resource "random_password" "execucao" {
  length  = 40
  special = false
}

resource "aws_db_instance" "execucao" {
  identifier = "${local.name}-execucao-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.execucao_db_name
  username = var.execucao_db_username
  password = random_password.execucao.result
  port     = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "06:00-07:00"
  maintenance_window      = "sun:07:30-sun:08:30"

  auto_minor_version_upgrade = true

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection = var.deletion_protection
  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${local.name}-execucao-postgres", Servico = "oficina-execucao" }
}

resource "aws_ssm_parameter" "execucao_database_url" {
  name        = "${local.ssm_prefix}/db/execucao_database_url"
  description = "DATABASE_URL do banco próprio do serviço de execução; lida pelo pipeline de oficina-execucao"
  type        = "SecureString"
  value = format(
    "postgresql://%s:%s@%s/%s?schema=public&connection_limit=5&pool_timeout=20",
    aws_db_instance.execucao.username,
    random_password.execucao.result,
    aws_db_instance.execucao.endpoint,
    aws_db_instance.execucao.db_name,
  )
}

output "execucao_db_endpoint" {
  description = "Endpoint do RDS do serviço de execução"
  value       = aws_db_instance.execucao.endpoint
}
