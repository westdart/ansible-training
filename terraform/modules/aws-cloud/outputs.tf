output "vpc-id" {
  value = aws_vpc.cloud.id
}

output "public-security-group" {
  value = aws_security_group.cloud-ssh.id
}

output "ingres-security-group" {
  value = aws_security_group.web-public-ingress.id
}

output "egres-security-group" {
  value = aws_security_group.web-public-egress.id
}

output "public_route_id" {
  value = aws_route_table.public_route.id
}