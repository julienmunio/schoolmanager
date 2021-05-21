locals {
  tags = {
    PROJECT     = var.project
    CLIENT      = var.client
    MANAGED_BY  = "terraform"
    Envrionment = var.environment
  }

  name = "${var.client}-${var.project}-${lower(var.environment)}"

  account = data.aws_caller_identity.main.account_id
  dns     = var.dns_zone
}

data "aws_caller_identity" "main" {}
