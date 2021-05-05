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

  user_data = join(
    "\n",
    [
      file("${path.module}/user_data/01-init.sh"),
      file("${path.module}/user_data/02-functions.sh"),
      templatefile("${path.module}/user_data/03-scripts.sh", {
        vpc_ip      = split("/", data.aws_vpc.default.cidr_block)[0],
        vpc_netmask = cidrnetmask(data.aws_vpc.default.cidr_block)
      }),
      templatefile("${path.module}/user_data/04-consul.sh", {
        consul_cluster_tag_key   = var.cluster_tag_key,
        consul_cluster_tag_value = var.cluster_tag_value
      }),
      "echo \"UserData done\""
    ]
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
    description = "OpenVPN"
    from_port   = 1194
    protocol    = "udp"
    to_port     = 1194
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN"
    from_port   = 943
    protocol    = "tcp"
    to_port     = 943
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

