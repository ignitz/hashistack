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
    description = "Kafka Connect REST"
    from_port   = 8083
    protocol    = "tcp"
    to_port     = 8083
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

