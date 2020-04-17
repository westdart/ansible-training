data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "arn" {
  value = data.aws_caller_identity.current.arn
}

output "user" {
  value = data.aws_caller_identity.current.user_id
}

output "id" {
  value = data.aws_caller_identity.current.id
}
