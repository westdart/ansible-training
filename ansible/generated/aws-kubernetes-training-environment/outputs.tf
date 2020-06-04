# Ansible managed
output "vpc" {
  value = aws_vpc.cloud
}
output "vpc_id" {
  value = local.vpc_id
}
output "machine_k1-kube1_localdomain" {
  value = aws_instance.k1_kube_instance_1
}
output "machine_k1-kube2_localdomain" {
  value = aws_instance.k1_kube_instance_2
}
