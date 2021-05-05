resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.kafka_storage.id
  instance_id = aws_instance.this.id
}

resource "aws_ebs_volume" "kafka_storage" {
  availability_zone = data.aws_subnet.get_availability_zone.availability_zone
  type              = "st1"
  size              = var.extended_volume_size

  tags = var.tags
}

data "aws_subnet" "get_availability_zone" {
  id = element(sort(data.aws_subnet_ids.default.ids), (var.kafka_id - 1) % length(data.aws_subnet_ids.default.ids))
}
