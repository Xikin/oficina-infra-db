provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "oficina-infra-db"
    }
  }
}

locals {
  name       = "${var.project}-${var.environment}"
  ssm_prefix = "/${var.project}/${var.environment}"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${local.ssm_prefix}/network/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "${local.ssm_prefix}/network/private_subnet_ids"
}

data "aws_ssm_parameter" "node_security_group_id" {
  name = "${local.ssm_prefix}/eks/node_security_group_id"
}

locals {
  vpc_id                 = data.aws_ssm_parameter.vpc_id.value
  private_subnet_ids     = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
  node_security_group_id = data.aws_ssm_parameter.node_security_group_id.value
}
