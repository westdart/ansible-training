# Expose terraform variables in the form Ansible can digest
terraform_vars: {
  'k1': {
    kubernetes_node_hosts: [
%{ for entry in split(",", k1_kubernetes_node_addresses) }
      ${entry},
%{ endfor }
    ] 
  }
}