module "zookeeper" {
  count  = 3
  source = "./zookeeper"

  instance_name = upper("${var.company}-kafka-zookeeper${count.index + 1}-${var.environment}")
  instance_type = "t3a.micro"
  ami_id        = var.ami_id
  ssh_key_name  = var.ssh_key_name
  environment   = var.environment

  zookeeper_id = count.index + 1 # start with zero, in zookeeper need 1, 2, 3

  # Join consul cluster
  consul_cluster_tag_key   = "consul-cluster"
  consul_cluster_tag_value = var.consul_cluster_tag_value

  tags = merge(
    var.tags,
    {
      application = "zookeeper"
    }
  )

  # Filter tags to find VPC and subnets
  use_default_vpc = false
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    # Type = "private"
    Type = "public"
  }
}


module "kafka" {
  count  = 3
  source = "./kafka"

  instance_name = upper("${var.company}-kafka-broker${count.index + 1}-${var.environment}")
  instance_type = "t3a.medium"
  ami_id        = var.ami_id
  ssh_key_name  = var.ssh_key_name
  environment   = var.environment

  extended_volume_size = 500

  kafka_id = count.index + 1 # start with zero, in zookeeper need 1, 2, 3

  # Join consul cluster
  consul_cluster_tag_key   = "consul-cluster"
  consul_cluster_tag_value = var.consul_cluster_tag_value

  tags = merge(
    var.tags,
    {
      application = "kafka"
    }
  )

  # Filter tags to find VPC and subnets
  use_default_vpc = false
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    # Type = "private"
    Type = "public"
  }

  depends_on = [
    module.zookeeper
  ]
}

module "schema-registry" {
  source = "./schema_registry"

  instance_name = upper("${var.company}-kafka-schema-registry-${var.environment}")
  instance_type = "t3a.micro"
  ami_id        = var.ami_id
  ssh_key_name  = var.ssh_key_name
  environment   = var.environment

  # Join consul cluster
  consul_cluster_tag_key   = "consul-cluster"
  consul_cluster_tag_value = var.consul_cluster_tag_value

  tags = merge(
    var.tags,
    {
      application = "schema-registry"
    }
  )

  # Filter tags to find VPC and subnets
  use_default_vpc = false
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    # Type = "private"
    Type = "public"
  }

  depends_on = [
    module.kafka
  ]
}

module "kafka-connect" {
  source = "./kafka_connect"

  instance_name = upper("${var.company}-kafka-connect-${var.environment}")
  instance_type = "t3a.medium"
  ami_id        = var.ami_id
  ssh_key_name  = var.ssh_key_name
  environment   = var.environment

  # Join consul cluster
  consul_cluster_tag_key   = "consul-cluster"
  consul_cluster_tag_value = var.consul_cluster_tag_value

  tags = merge(
    var.tags,
    {
      application = "kafka-connect"
    }
  )

  # Filter tags to find VPC and subnets
  use_default_vpc = false
  vpc_tags = {
    Name = var.vpc_name
  }
  subnet_tags = {
    # Type = "private"
    Type = "public"
  }

  depends_on = [
    module.schema-registry
  ]
}


# module "postgres" {
#   source = "./database/mock"

#   instance_name = upper("${var.company}-kafka-kafka-connect-${var.environment}")
#   instance_type = "t3a.medium"
#   ami_id        = var.ami_id
#   ssh_key_name  = var.ssh_key_name
#   environment   = var.environment

#   # Join consul cluster
#   consul_cluster_tag_key   = "consul-cluster"
#   consul_cluster_tag_value = var.consul_cluster_tag_value

#   tags = merge(
#     var.tags,
#     {
#       application = "kafka-connect"
#     }
#   )

#   # Filter tags to find VPC and subnets
#   use_default_vpc = false
#   vpc_tags = {
#     Name = var.vpc_name
#   }
#   subnet_tags = {
#     # Type = "private"
#     Type = "public"
#   }

#   depends_on = [
#     module.vault
#   ]
# }
