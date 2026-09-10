# ---------------------------------------------------------------------------
# Contrato com os demais repositórios
#
#   oficina-mvp         -> lê database_url no deploy e cria o Secret do Kubernetes
#   oficina-auth-lambda -> lê database_url e db_client_security_group_id
#
# SecureString usa a chave KMS gerenciada da AWS (alias/aws/ssm), que é
# gratuita. Secrets Manager cobraria US$0,40/segredo/mês e ofereceria rotação
# automática — desnecessária no escopo do desafio.
# ---------------------------------------------------------------------------

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

# Connection string pronta no formato que o Prisma espera. Evita que cada
# consumidor remonte a URL e erre a codificação.
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

# "Crachá" de acesso ao banco: a Lambda anexa este SG à sua ENI.
resource "aws_ssm_parameter" "db_client_security_group_id" {
  name        = "${local.ssm_prefix}/db/client_security_group_id"
  description = "Security group que concede acesso ao PostgreSQL"
  type        = "String"
  value       = aws_security_group.db_client.id
}
