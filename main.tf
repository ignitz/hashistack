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

  vpc_name = var.hashitack.vpc_name

  ssh_key_name = var.hashitack.ssh_key_name

  amis = var.hashitack.amis
}
