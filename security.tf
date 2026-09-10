# ---------------------------------------------------------------------------
# Security groups
#
# Dois grupos, para que o acesso ao banco seja concedido por identidade e não
# por faixa de IP:
#
#   db_client -> SG "crachá". Quem o anexa ganha acesso ao banco.
#                A Lambda de autenticação usa este, lendo o ID pelo SSM.
#   database  -> SG do RDS. Só aceita 5432 vindo do SG dos nós do EKS e do
#                SG de cliente. Sem CIDR aberto, sem 0.0.0.0/0.
# ---------------------------------------------------------------------------

resource "aws_security_group" "db_client" {
  name        = "${local.name}-db-client"
  description = "Concede acesso ao PostgreSQL a quem anexa este security group"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-db-client" }
}

resource "aws_security_group" "database" {
  name        = "${local.name}-db"
  description = "RDS PostgreSQL da oficina"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-db" }
}

resource "aws_vpc_security_group_ingress_rule" "from_eks_nodes" {
  security_group_id = aws_security_group.database.id
  description       = "PostgreSQL a partir dos nos do cluster EKS (API)"

  referenced_security_group_id = local.node_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "from_db_clients" {
  security_group_id = aws_security_group.database.id
  description       = "PostgreSQL a partir da Lambda de autenticacao"

  referenced_security_group_id = aws_security_group.db_client.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# O RDS não inicia conexões de saída, mas o SG exige uma regra de egress
# explícita para não herdar o "permitir tudo" default.
resource "aws_vpc_security_group_egress_rule" "database_none" {
  security_group_id = aws_security_group.database.id
  description       = "Sem trafego de saida iniciado pelo banco"

  cidr_ipv4   = "127.0.0.1/32"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "db_client_to_database" {
  security_group_id = aws_security_group.db_client.id
  description       = "Saida para o PostgreSQL"

  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
