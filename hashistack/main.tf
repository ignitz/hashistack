data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  consul_cluster_tag_value = upper("${var.company}-demo-consul-${var.environment}")
}

terraform {
  # https://zenn.dev/oke_py/articles/048ffb5135c4b9ece974
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


module "vault_consul" {
  source = "./vault_consul"

  ami_id                 = var.amis.consul_vault_ami
  ssh_key_name           = var.ssh_key_name
  consul_cluster_name    = upper("${var.company}-demo-consul-${var.environment}")
  vault_cluster_name     = upper("${var.company}-demo-vault-${var.environment}")
  consul_cluster_tag_key = "consul-cluster"
  environment            = var.environment

  # Set nodes quantity to each environment. In production we will have a cluster
  vault_cluster_size  = contains(["DEV", "STAGING", "TEST"], var.environment) ? 1 : 3
  consul_cluster_size = contains(["DEV", "STAGING", "TEST"], var.environment) ? 1 : 3

  # vault s3 backend
  vault_s3_bucket_name = lower("${var.company}-${local.account_id}-vault-backend-${var.environment}")
  vault_s3_tags = {
    Name    = lower("${var.company}-${local.account_id}-vault-backend-${var.environment}")
    Region  = local.region
    Stack   = var.environment
    Purpose = "Bucket responsible for storing the vault backend data in ${var.environment} environment"
  }

  tags = {
    OS                 = "ubuntu"
    Region             = local.region
    environment        = var.environment
  }

  use_default_vpc = false
  # TODO: Need to have better tags
  # Filter tags
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    Type = "public"
  }
}

module "openvpn-server" {
  count  = 1 # Disable until I wanna use
  source = "./vpn-server"

  instance_name = upper("${var.company}-demo-openvpn-${var.environment}")
  ami_id        = var.amis.openvpn_ami
  ssh_key_name  = var.ssh_key_name
  environment   = var.environment

  # Join consul cluster
  cluster_tag_key = "consul-cluster"
  # TODO: make a output in consul to add here
  cluster_tag_value = upper("${var.company}-demo-consul-${var.environment}")

  tags = {
    OS                 = "ubuntu"
    Region             = local.region
    application        = "OpenVPN"
    environment        = var.environment
  }

  # Filter tags
  use_default_vpc = false
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    # Type = "private"
    Type = "public"
  }
}

################################################
# Setup do Kafka com zookeeper
################################################
module "kafka_stack" {
  source = "./kafka_stack"

  company      = var.company
  ami_id       = var.amis.metadata_publisher_ami # TODO: change
  ssh_key_name = var.ssh_key_name
  environment  = var.environment

  # Join consul cluster
  consul_cluster_tag_value = local.consul_cluster_tag_value

  tags = {
    OS                 = "ubuntu"
    Region             = local.region
    environment        = var.environment
  }

  vpc_name = var.vpc_name
}
