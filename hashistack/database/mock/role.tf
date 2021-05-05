resource "aws_iam_role" "assume_role" {
  name = upper("${var.instance_name}-role")
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "auto_discover" {
  name        = upper("${var.instance_name}-policy")
  description = "Auto discover consul cluster with EC2's tags."
  policy      = data.template_file.auto_discover.rendered
}

data "template_file" "auto_discover" {
  template = file("${path.module}/policies/auto_discover.json")
}

resource "aws_iam_policy_attachment" "role_attachment" {
  name       = upper("${var.instance_name}-role-attach")
  roles      = [aws_iam_role.assume_role.name]
  policy_arn = aws_iam_policy.auto_discover.arn
}

resource "aws_iam_instance_profile" "role_profile" {
  name = upper("${var.instance_name}-role-profile")
  role = aws_iam_role.assume_role.name
}
