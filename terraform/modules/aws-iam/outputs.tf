output "sts-instance-profile-id" {
  value = aws_iam_instance_profile.sts-instance-profile.id
}

output "application-user-id" {
  value = aws_iam_user.application-aws-user.id
}

output "application-user-name" {
  value = aws_iam_user.application-aws-user.name
}

output "application-user-access-key" {
  value = aws_iam_access_key.application-aws-user.id
}

output "application-user-access-secret" {
  value = aws_iam_access_key.application-aws-user.secret
}
