resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )

  key_name               = var.ssh_key_name
  iam_instance_profile   = aws_iam_instance_profile.role_profile.name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = join(
    "\n",
    [
      file("${path.module}/user_data/01-init_instance.sh"),
      file("${path.module}/user_data/02-attach_ebs.sh"),
      "mkdir -pv /home/ubuntu/kafka",
      "cat > /home/ubuntu/kafka/docker-compose.yaml << 'EOL'",
      templatefile("${path.module}/user_data/docker-compose.yaml", {
        KAFKA_ID = var.kafka_id
      }),
      "EOL",
      "docker-compose -f /home/ubuntu/kafka/docker-compose.yaml up -d",
      file("${path.module}/user_data/03-monitoring.sh"),
      templatefile("${path.module}/user_data/04-consul.sh", {
        consul_cluster_tag_key   = var.consul_cluster_tag_key,
        consul_cluster_tag_value = var.consul_cluster_tag_value
        KAFKA_ID                 = var.kafka_id
      })
    ]
  )

  subnet_id = element(sort(data.aws_subnet_ids.default.ids), (var.kafka_id - 1) % length(data.aws_subnet_ids.default.ids))

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }
}

resource "aws_security_group" "sg" {
  name        = var.instance_name
  description = "Acesso ao Zookeeper"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "Acesso SSH"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "Kafka comunication"
    from_port   = 9092
    protocol    = "tcp"
    to_port     = 9094
  }

  ingress {
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "NETDATA"
    from_port   = 19999
    protocol    = "tcp"
    to_port     = 19999
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = var.instance_name
  }
}

# Find existent VPC by tags
data "aws_vpc" "default" {
  default = var.use_default_vpc
  tags    = var.vpc_tags
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
  tags   = var.subnet_tags
}

