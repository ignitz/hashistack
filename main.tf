locals {
  # Considering branch main and master as production environment
  environment = contains(["master", "main"], terraform.workspace) ? "PRODUCTION" : upper(terraform.workspace)
}

module "hashistack" {
  source = "./hashistack"

  providers = {
    aws = aws.hashistack
  }

  company     = "yuriniitsuma"
  environment = local.environment

  vpc_name = var.hashistack.vpc_name

  ssh_key_name = var.hashistack.ssh_key_name

  amis = var.hashistack.amis
}
