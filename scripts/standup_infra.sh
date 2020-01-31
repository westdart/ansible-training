#!/usr/bin/env bash

########################################################################################################################
# Simple script to stand up the infrastructure prerequisites on the user's AWS instances
# This is a thin wrapper around the 'setup.yml' playbook, which is responsible for setting up the infrastructure.
# Currently only AWS is supported.
#
# Dependencies:
#   - The following secrets must be available:
#       AWS_ACCESS_KEY_ID
#       AWS_SECRET_ACCESS_KEY
#       local_sudo
#       vault_password
#       infra_vault_password
#
#     These can be setup by calling:
#       ./aws.sh -f setupSecrets
#
# Usage:
# ./standup_infra.sh -e <env-file>
#
########################################################################################################################
DIR=
DIR="$( cd "$( dirname ${BASH_SOURCE[0]} )" >/dev/null 2>&1 && pwd )" || {
    echo "ERROR: Failed to get script directory."
    exit 1
}
ANSIBLE_DIR="$( cd "${DIR}/../ansible" >/dev/null 2>&1 && pwd )" || {
    echo "ERROR: Failed to get ansible directory."
    exit 1
}

ADDITONAL_ARGS_PATTERN='+(-e|--envspec|-p|--password|-v|--virtualenv|--vault)'
ADDITONAL_SWITCHES_PATTERN=''

source "${DIR}/wrapper.sh"
source "${DIR}/common-properties.sh"

[[ -z "$VAULT" ]]       && VAULT="~/.vaults/ansible-training.vault"
[[ -z "$VIRTUAL_ENV" ]] && VIRTUAL_ENV="vaws3"
VAULT_PASSWORD=
VAULT_PASSWORD_FILE="${DIR}/.vp$$"

function wrapper_initialise()
{
    activateVirtualEnv  || { log_error "Failed to activate virtual env"; return 1; }

    haveSecret vault_password || ${DIR}/aws.sh -f setupSecrets
    haveSecret vault_password || { log_error "Failed to obtain secrets"; return 1; }

    VAULT_PASSWORD=$(getSecret vault_password)

    addTempFiles $VAULT_PASSWORD_FILE

    echo "${VAULT_PASSWORD}" > ${VAULT_PASSWORD_FILE}
    chmod 600 "${VAULT_PASSWORD_FILE}"

    pushd "${ANSIBLE_DIR}" >& /dev/null || { log_error "Unable to find ansible dir \"${ANSIBLE_DIR}\""; exit 1; }
    log_debug "ansible_dir=${ANSIBLE_DIR}, $(pwd)"
}

function executeCommand()
{
    # Execute an Ansible playbook
    log_debug "ansible-playbook playbooks/${1}.yml $(getAnsibleDebugClause) -i $(getInventoryDir) " \
              "--extra-vars \"env_spec=$(getEnvSpecFile)\"" \
              "--extra-vars \"ansible_sudo_pass=$(getSecret local_sudo)\"" \
              "--extra-vars \"infra_secret_passphrase=$(getSecret infra_vault_password)\"" \
              "--extra-vars \"vault=${VAULT}\"" \
              "--vault-password-file \"${VAULT_PASSWORD_FILE}\""
    ansible-playbook playbooks/${1}.yml $(getAnsibleDebugClause) -i $(getInventoryDir)\
            --extra-vars "env_spec=$(getEnvSpecFile)" \
            --extra-vars "ansible_sudo_pass=$(getSecret local_sudo)" \
            --extra-vars "infra_secret_passphrase=$(getSecret infra_vault_password)" \
            --extra-vars "vault=${VAULT}" \
            --vault-password-file "${VAULT_PASSWORD_FILE}"
}

function activateVirtualEnv() {
    declare venv="${HOME}/python-virtual-envs/${VIRTUAL_ENV}/bin/activate"
    source "${venv}"
}

function main()
{
    executeCommand setup
}

function generateTerraformConfig() {
    executeCommand genterra-main
}

function generateTerraformSecrets() {
    executeCommand genterra-secrets
}

function buildInfra() {
    executeCommand build-infra
}

function generateAnsibleInventory() {
    executeCommand gen-ansible-inventory
}

function generateHostsFile() {
    executeCommand gen-hosts
}

########################################################################################################################
# Sets up target machines and optionally installs an OpenShift cluster
# This function assumes that secrets have been setup using './aws.sh -f setupSecrets' prior to function being called.
########################################################################################################################
function executeScript() {
    main || return 1
}

function usage() {
  log_always "Usage: $0 -i initials -v <virtualenv> -p password"
}

function extractArgs() {
    local arg_key=
    local optarg=
    while [[ $# -gt 0 ]]
    do
      arg_key="$1"
      optarg=
      if [ $# -gt 1 ]
      then
        optarg="$2"
      fi
      case ${arg_key} in
        -e|--envspec)
            setOption "${arg_key}" "ENVSPEC" "${optarg}"
            shift # past argument
            ;;
        -v|--virtualenv)
            setOption "${arg_key}" "VIRTUAL_ENV" "${optarg}"
            shift # past argument
            ;;
        --vault)
            setOption "${arg_key}" "VAULT" "${optarg}"
            shift # past argument
            ;;
      esac
      shift # past argument or value
    done

    [[ -z "${VIRTUAL_ENV}" ]] && { log_error "The ost-* playbooks require a Python virtual environment (-v <virtual_env>)"; return 1; }

    [[ -f "$(getEnvSpecFile)" ]] || { log_error "The infra playbooks require an envspec (i.e. '--envspec parameter set to name of a file in ${ANSIBLE_DIR}/varfiles)"; return 1; }

    return 0
}

wrapper

declare -i status=$?
exit ${status}
