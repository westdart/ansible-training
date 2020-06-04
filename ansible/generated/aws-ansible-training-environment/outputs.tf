# Ansible managed
output "vpc" {
  value = aws_vpc.cloud
}
output "vpc_id" {
  value = local.vpc_id
}
output "machine_t1-tnode1_at_local" {
  value = aws_instance.t1_tnode_instance_1
}
output "machine_t1-tnode2_at_local" {
  value = aws_instance.t1_tnode_instance_2
}
output "machine_t1-tnode3_at_local" {
  value = aws_instance.t1_tnode_instance_3
}
