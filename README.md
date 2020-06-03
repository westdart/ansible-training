# ansible-training

## Commands

### Construct infrastructure

```
# ansible-playbook playbooks/build-infra.yml \
    -i generated/aws-kubernetes-training-environment/inventory \
    --extra-vars "env_spec=./varfiles/aws-kubernetes-training-environment.yml" \
    --extra-vars "vault=~/.vaults/ansible-training.vault" \
    --vault-id cred@~/.vaults/ansible-training-pwd.txt
```

### Stop machines
To stop all machines in eu-west-2:
```
# ansible-playbook playbooks/stop.yml \
    -i generated/aws-kubernetes-training-environment/inventory \
    --extra-vars 'target=all' \
    --extra-vars 'infra_region=eu-west-2'
```

### Start machines
To stop all machines in eu-west-2:
```
# ansible-playbook playbooks/start.yml \
    -i generated/aws-kubernetes-training-environment/inventory \
    --extra-vars 'target=k1' \
    --extra-vars 'infra_region=eu-west-2' \
    --extra-vars 'env_spec=./varfiles/aws-kubernetes-training-environment.yml'
```
