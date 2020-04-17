# Expose terraform variables in the form Ansible can digest
terraform_vars: {
  'o1': {
    anode_hosts: [
%{ for entry in split(",", o1_anode_addresses) }
      ${entry},
%{ endfor }
    ] 
  }
}