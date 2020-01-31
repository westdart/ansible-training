# Expose terraform variables in the form Ansible can digest
terraform_vars: {
  't1': {
    tnode_hosts: [
%{ for entry in split(",", t1_tnode_addresses) }
      ${entry},
%{ endfor }
    ] 
  }
}