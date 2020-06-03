# Ansible managed
output "vpc" {
  value = aws_vpc.cloud
}
output "vpc_id" {
  value = local.vpc_id
}
output "machine_k1-kubernetes_node1_localdomain" {
  value = aws_instance.k1_kubernetes_node_instance_1
}
output "machine_k1-kubernetes_node2_localdomain" {
  value = aws_instance.k1_kubernetes_node_instance_2
}
