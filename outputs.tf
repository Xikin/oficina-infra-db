output "db_endpoint" {
  description = "Endpoint host:porta do RDS"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Nome do banco inicial"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Usuário master"
  value       = aws_db_instance.this.username
}

output "database_url_ssm_parameter" {
  description = "Parâmetro SSM que guarda a DATABASE_URL (SecureString)"
  value       = aws_ssm_parameter.database_url.name
}

output "db_client_security_group_id" {
  description = "Anexe este security group a qualquer recurso que precise falar com o banco"
  value       = aws_security_group.db_client.id
}

output "database_url" {
  description = "Connection string completa — só é exibida com `terraform output -raw database_url`"
  value       = aws_ssm_parameter.database_url.value
  sensitive   = true
}
