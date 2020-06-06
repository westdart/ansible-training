# Ansible managed
output "vpc" {
  value = module.aws-cloud2.vpc
}
output "vpc_id" {
  value = module.aws-cloud2.vpc-id
}
