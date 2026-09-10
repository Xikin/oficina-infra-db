# ---------------------------------------------------------------------------
# RDS PostgreSQL gerenciado
#
# Substitui o Deployment de Postgres que rodava dentro do cluster na Fase 2
# (k8s/postgres-deployment.yaml + postgres-pvc.yaml), conforme a RFC-0002.
# ---------------------------------------------------------------------------

resource "random_password" "master" {
  # A senha entra numa connection string (postgresql://user:senha@host/db).
  # Caracteres como %, #, ? e : mudam o significado da URL e quebram o parser
  # do Prisma de formas difíceis de diagnosticar. 40 caracteres alfanuméricos
  # dão ~238 bits de entropia — mais do que suficiente, e sem escape nenhum.
  length  = 40
  special = false
}

resource "aws_db_subnet_group" "this" {
  name        = "${local.name}-db-subnets"
  description = "Subnets privadas da VPC da oficina"
  subnet_ids  = local.private_subnet_ids

  tags = { Name = "${local.name}-db-subnets" }
}

# Grupo de parâmetros próprio: sem ele não dá para ligar o log de queries
# lentas, que é a base do painel de performance de banco no New Relic.
resource "aws_db_parameter_group" "this" {
  name        = "${local.name}-pg16"
  family      = "postgres16"
  description = "Parametros do PostgreSQL da oficina"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # loga toda query acima de 1s
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result
  port     = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  # O banco vive em subnet privada e nunca recebe IP público.
  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "06:00-07:00" # 03:00-04:00 BRT, fora do horário da oficina
  maintenance_window      = "sun:07:30-sun:08:30"

  # Patches de segurança automáticos — um dos motivos de sair do Deployment
  # autogerido no cluster.
  auto_minor_version_upgrade = true

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection = var.deletion_protection
  # No lab, destruir é rotina; num ambiente real ambos seriam o oposto.
  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${local.name}-postgres" }
}
