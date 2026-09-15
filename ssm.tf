resource "aws_ssm_parameter" "db_endpoint" {
  name        = "${local.ssm_prefix}/db/endpoint"
  description = "Endpoint host:porta do RDS PostgreSQL"
  type        = "String"
  value       = aws_db_instance.this.endpoint
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${local.ssm_prefix}/db/name"
  type  = "String"
  value = aws_db_instance.this.db_name
}

resource "aws_ssm_parameter" "db_username" {
  name  = "${local.ssm_prefix}/db/username"
  type  = "String"
  value = aws_db_instance.this.username
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.ssm_prefix}/db/password"
  description = "Senha master gerada pelo Terraform"
  type        = "SecureString"
  value       = random_password.master.result
}

resource "aws_ssm_parameter" "database_url" {
  name        = "${local.ssm_prefix}/db/database_url"
  description = "DATABASE_URL no formato do Prisma"
  type        = "SecureString"
  value = format(
    "postgresql://%s:%s@%s/%s?schema=public&connection_limit=5&pool_timeout=20",
    aws_db_instance.this.username,
    random_password.master.result,
    aws_db_instance.this.endpoint,
    aws_db_instance.this.db_name,
  )
}

resource "aws_ssm_parameter" "db_client_security_group_id" {
  name        = "${local.ssm_prefix}/db/client_security_group_id"
  description = "Security group que concede acesso ao PostgreSQL"
  type        = "String"
  value       = aws_security_group.db_client.id
}
