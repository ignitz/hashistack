# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VAULT SERVER CLUSTER, AN ELB, AND A CONSUL SERVER CLUSTER IN AWS
# This is an example of how to use the vault-cluster and vault-elb modules to deploy a Vault cluster in AWS with an
# Elastic Load Balancer (ELB) in front of it. This cluster uses Consul, running in a separate cluster, as its storage
# backend.
# ---------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE VAULT SERVER CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "vault_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster?ref=v0.0.1"
  source = "./vault-cluster"

  cluster_name  = var.vault_cluster_name
  cluster_size  = var.vault_cluster_size
  instance_type = var.vault_instance_type

  ami_id    = var.ami_id
  user_data = data.template_file.user_data_vault_cluster.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # Do NOT use the ELB for the ASG health check, or the ASG will assume all sealed instances are unhealthy and
  # repeatedly try to redeploy them.
  health_check_type = "EC2"

  # To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  allowed_ssh_cidr_blocks              = [data.aws_vpc.default.cidr_block]
  allowed_inbound_cidr_blocks          = [data.aws_vpc.default.cidr_block]
  allowed_inbound_security_group_ids   = []
  allowed_inbound_security_group_count = 0
  ssh_key_name                         = var.ssh_key_name

  # Add S3 backend
  enable_s3_backend = true
  # Force to not destroy bucket in production and staging environment
  force_destroy_s3_bucket = contains(["STAGING", "PRODUCTION"], var.environment) ? false : true
  s3_bucket_name          = var.vault_s3_bucket_name
  s3_bucket_tags          = var.vault_s3_tags

  # Tags
  cluster_extra_tags = [for key, value in var.tags : {
    key                 = key
    value               = value
    propagate_at_launch = true
  }]
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES FOR CONSUL
# To allow our Vault servers to automatically discover the Consul servers, we need to give them the IAM permissions from
# the Consul AWS Module's consul-iam-policies module.
# ---------------------------------------------------------------------------------------------------------------------

module "consul_iam_policies_servers" {
  source = "./consul-iam-policies"

  iam_role_id = module.vault_cluster.iam_role_id
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH VAULT SERVER WHEN IT'S BOOTING
# This script will configure and start Vault
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_vault_cluster" {
  template = file("${path.module}/user-data/user-data-vault.sh")

  vars = {
    aws_region               = data.aws_region.current.name
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    s3_bucket_name           = var.vault_s3_bucket_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PERMIT CONSUL SPECIFIC TRAFFIC IN VAULT CLUSTER
# To allow our Vault servers consul agents to communicate with other consul agents and participate in the LAN gossip,
# we open up the consul specific protocols and ports for consul traffic
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "./consul-client-security-group-rules"

  security_group_id = module.vault_cluster.security_group_id

  # To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  allowed_inbound_cidr_blocks = [data.aws_vpc.default.cidr_block]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE ELB
# ---------------------------------------------------------------------------------------------------------------------

# Disable ELB to avoid unnecessary costs

# module "vault_elb" {
#   # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
#   # to a specific version of the modules, such as the following example:
#   # source = "github.com/hashicorp/terraform-aws-vault//modules/vault-elb?ref=v0.0.1"
#   source = "./vault-elb"

#   name = lower(var.vault_cluster_name)

#   vpc_id     = data.aws_vpc.default.id
#   subnet_ids = data.aws_subnet_ids.default.ids

#   # Associate the ELB with the instances created by the Vault Autoscaling group
#   vault_asg_name = module.vault_cluster.asg_name

#   # To make testing easier, we allow requests from any IP address here but in a production deployment, we *strongly*
#   # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
#   allowed_inbound_cidr_blocks = ["0.0.0.0/0"]

#   # In order to access Vault over HTTPS, we need a domain name that matches the TLS cert
#   create_dns_entry = var.create_dns_entry

#   # Terraform conditionals are not short-circuiting, so we use join as a workaround to avoid errors when the
#   # aws_route53_zone data source isn't actually set: https://github.com/hashicorp/hil/issues/50
#   hosted_zone_id = var.create_dns_entry ? join("", data.aws_route53_zone.selected.*.zone_id) : ""

#   domain_name = var.vault_domain_name
# }

# Look up the Route 53 Hosted Zone by domain name
data "aws_route53_zone" "selected" {
  count = var.create_dns_entry ? 1 : 0
  name  = "${var.hosted_zone_domain_name}."
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "consul_cluster" {
  source = "./consul-cluster"

  cluster_name  = var.consul_cluster_name
  cluster_size  = var.consul_cluster_size
  instance_type = var.consul_instance_type

  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = var.consul_cluster_tag_key
  cluster_tag_value = var.consul_cluster_name

  ami_id    = var.ami_id
  user_data = data.template_file.user_data_consul.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.

  allowed_ssh_cidr_blocks     = [data.aws_vpc.default.cidr_block]
  allowed_inbound_cidr_blocks = [data.aws_vpc.default.cidr_block]
  ssh_key_name                = var.ssh_key_name

  # tags  
  tags = [for key, value in var.tags : {
    key                 = key
    value               = value
    propagate_at_launch = true
  }]
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul" {
  template = file("${path.module}/user-data/user-data-consul.sh")

  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CLUSTERS IN THE DEFAULT VPC AND AVAILABILITY ZONES
# Using the default VPC and subnets makes this example easy to run and test, but it means Consul and Vault are
# accessible from the public Internet. In a production deployment, we strongly recommend deploying into a custom VPC
# and private subnets. Only the ELB should run in the public subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = var.use_default_vpc
  tags    = var.vpc_tags
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
  tags   = var.subnet_tags
}

data "aws_region" "current" {
}

