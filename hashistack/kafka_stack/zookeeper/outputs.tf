output "this" {
  value = aws_instance.this
}

output "sg" {
  value = aws_security_group.sg
}

# output "iam" {
#   value = {
#     role   = aws_iam_role.assume_role
#     policy = aws_iam_role.policy
#   }
# }
