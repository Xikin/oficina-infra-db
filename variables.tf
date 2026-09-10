variable "region" {
  description = "Região AWS — precisa ser a mesma da stack oficina-infra-k8s"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo aplicado ao nome de todos os recursos"
  type        = string
  default     = "oficina"
}

variable "environment" {
  description = "Ambiente lógico desta stack (homolog ou prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["homolog", "prod"], var.environment)
    error_message = "environment deve ser 'homolog' ou 'prod'."
  }
}

variable "engine_version" {
  description = "Versão do PostgreSQL. Alinhada com a imagem postgres:16 usada em desenvolvimento."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "Classe da instância. db.t3.micro é elegível ao free tier (750h/mês)."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento inicial em GB (o free tier cobre até 20)"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "O RDS exige no mínimo 20 GB para gp3."
  }
}

variable "max_allocated_storage" {
  description = "Teto do autoscaling de storage. Zero desliga o autoscaling."
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Nome do banco inicial"
  type        = string
  default     = "oficina_db"
}

variable "db_username" {
  description = "Usuário master. 'admin' e 'postgres' são reservados pelo RDS."
  type        = string
  default     = "oficina"
}

variable "backup_retention_period" {
  description = "Dias de retenção de backup automático. Zero desliga os backups."
  type        = number
  default     = 7
}

variable "multi_az" {
  description = <<-EOT
    Alta disponibilidade com standby em outra AZ.
    Dobra o custo — mantido desligado no Learner Lab.
  EOT
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = <<-EOT
    Impede `terraform destroy` de apagar o banco.
    Falso no lab justamente porque destruir entre sessões é rotina.
  EOT
  type        = bool
  default     = false
}
