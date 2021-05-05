# Elastic IP to OpenVPN Server

resource "aws_eip" "instance" {
  instance = aws_instance.instance.id
  vpc      = true

  tags = merge(
    {
      Name = var.instance_name
    },
    var.tags
  )
}
