# Find existent VPC by tags
data "aws_vpc" "default" {
  default = var.use_default_vpc
  tags    = var.vpc_tags
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
  tags   = var.subnet_tags
}

