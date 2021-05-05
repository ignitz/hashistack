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
      "mkdir -pv /home/ubuntu/kafka-connect",
      "apt install -y git",
      "cat > /home/ubuntu/kafka-connect/docker-compose.yaml << 'EOL'",
      file("${path.module}/user_data/docker-compose.yaml"),
      "EOL",
      "docker-compose -f /home/ubuntu/kafka-connect/docker-compose.yaml up -d",
      file("${path.module}/user_data/02-monitoring.sh"),
      templatefile("${path.module}/user_data/03-consul.sh", {
        consul_cluster_tag_key   = var.consul_cluster_tag_key,
        consul_cluster_tag_value = var.consul_cluster_tag_value
      })
    ]
  )

  subnet_id = element(sort(data.aws_subnet_ids.default.ids), 0)

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }
}

