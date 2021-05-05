resource "aws_instance" "instance" {
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
  user_data = base64encode(
    join(
      "\n",
      [
        file("${path.module}/user_data/01-init_instance.sh"),
        "mkdir -pv /home/ubuntu/postgres",
        "cat > /home/ubuntu/postgres/docker-compose.yaml << 'EOL'",
        file("${path.module}/user_data/docker-compose.yaml"),
        "EOL",
        "docker-compose -f /home/ubuntu/postgres/docker-compose.yaml up -d",
        templatefile("${path.module}/user_data/02-consul.sh", {
          consul_cluster_tag_key   = var.consul_cluster_tag_key,
          consul_cluster_tag_value = var.consul_cluster_tag_value
        }),
        "sleep 30",
        "docker exec postgres psql -U postgres -c 'CREATE DATABASE airflow'"
      ]
    )
  )

  subnet_id = element(sort(data.aws_subnet_ids.default.ids), 0)
}

resource "aws_security_group" "sg" {
  name        = var.instance_name
  description = "Acesso ao OpenVPN"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acesso SSH"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Postgres"
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # TODO: Add tags and fix name
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

