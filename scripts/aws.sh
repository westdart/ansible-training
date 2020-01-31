#!/usr/bin/env bash

########################################################################################################################
# Simple wrapper around aws commands that execute on only the user's instances
########################################################################################################################
DIR=
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || {
    echo "ERROR: Failed to get script directory."
    exit 1
}
ANSIBLE_DIR="$( cd "${DIR}/../ansible" >/dev/null 2>&1 && pwd )" || {
    echo "ERROR: gfdg Failed to get ansible directory."
    exit 1
}

NAME=
NAME="$(basename "${BASH_SOURCE[0]}" )"

SCRIPT="${DIR}/${NAME}"

ADDITONAL_ARGS_PATTERN='+(-e|--envspec|-c|--command|-i|--id|-v|--virtualenv|-p|--password|--inv|--vault|-x|--extra-vars)'
ADDITONAL_SWITCHES_PATTERN=''

source "${DIR}/wrapper.sh"
source "${DIR}/common-properties.sh"

COMMAND=
[[ -z "$VAULT" ]]       && VAULT="~/.vaults/local.vault"
[[ -z "$VIRTUAL_ENV" ]] && VIRTUAL_ENV="vaws"
[[ -z "$ENV_ID" ]]      && ENV_ID="${INITIALS}"
ENVSPEC=
EXTRA_VARS=

RED='\033[1;31m'
NC='\033[0m' # No Color

function wrapper_initialise()
{
    activateVirtualEnv  || { log_error "Failed to activate virtual env"; return 1; }

    if [[ -z "${FUNC}" ]]
    then
        validateInventoryDir || { log_error "Failed to validate inventory dir"; return 1; }
    fi

    pushd "${ANSIBLE_DIR}" >& /dev/null || {
        log_error "Unable to find ansible dir \"${ANSIBLE_DIR}\""
        exit 1
    }
    log_debug "ansible_dir=${ANSIBLE_DIR}, $(pwd)"
}

function wrapper_finalise()
{
    popd >& /dev/null || log_error "Failed to pop directory."
}

function validateInventoryDir() {
    local path="${ANSIBLE_DIR}/$(getInventoryDir)"

    path="$(readlink -fm "${path}")" || {
        log_error "Failed to resolve the ansible inventory directory ${path}."
        return 1
    }

    if [[ ! -e "${path}" ]]; then
        log_error "The ansible inventory directory ${path} does not exist."
        return 1
    fi

    if [[ ! -d "${path}" ]]; then
        log_error "The ansible inventory directory ${path} is not a directory."
        return 1
    fi
}

function activateVirtualEnv() {
    declare venv="${HOME}/python-virtual-envs/${VIRTUAL_ENV}/bin/activate"
    log_info "HOME=${HOME}"
    log_info "venv=${venv}"

    [[ -f "${venv}" ]] || {
        log_error "The virtual environment ${VIRTUAL_ENV} (${venv}) cannot be activated."
        return 1
    }

    source "${venv}"
}

function overwrite()
{
    local secret=$1
    local result=0
    if haveSecret $secret
    then
        log_always "The secret '$secret' already exists. Overwrite? [y/n]"
        ! confirmed && result=1
    fi
    return $result
}

########################################################################################################################
# Call this function once to setup the required secrets
#  i.e. ./aws.sh -f setupSecrets
# (sudo password used after server restart in setting the /etc/hosts file)
########################################################################################################################
function setupSecrets()
{
    overwrite "local_sudo"            && storeSecret "local_sudo"
    overwrite "vault_password"        && storeSecret "vault_password"
    overwrite "infra_vault_password"  && storeSecret "infra_vault_password"
    overwrite "AWS_ACCESS_KEY_ID"     && storeSecret "AWS_ACCESS_KEY_ID"
    overwrite "AWS_SECRET_ACCESS_KEY" && storeSecret "AWS_SECRET_ACCESS_KEY"
}

function secretPassphrase {
    getSecret vault_password
}

function getTarget() {
    [[ "${ENV_ID}" == "all" ]] && { echo "target=all"; return 0; }
    # Read the ENV_ID into bash array (ENV_ID is comma separated)
    _IFS=$IFS
    IFS=',' read -r -a targets <<< "$ENV_ID"
    IFS=$_IFS

    # Create a json array from the bash array, called 'target'
    result='{"target":'
    result="$result $(printf '%s\n' "${targets[@]}" | jq -R . | jq -s .) }"

    # Remove newlines and extra spaces from json array
    echo "${result}" | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ \+/ /g'
}

function extraArgsClause() {
    [[ ! -z "$EXTRA_VARS" ]] && echo "--extra-vars '${EXTRA_VARS}'"
}

function startInstances() {
    local vault_password_file="${DIR}/.vp$$"
    addTempFiles "${vault_password_file}"
    echo "$(secretPassphrase)" > "${vault_password_file}"
    chmod 600 "${vault_password_file}"

    cmd="ansible-playbook playbooks/start.yml -i $(getInventoryDir) --extra-vars '$(getTarget)' \
--extra-vars ansible_sudo_pass=\"$(getSecret local_sudo)\" $(extraArgsClause) \
--extra-vars \"vault=${VAULT}\" --vault-password-file \"${vault_password_file}\""
    log_debug "Start command: $cmd"
    eval $cmd
}

function stopInstances() {
    ansible-playbook playbooks/stop.yml -i "$(getInventoryDir)" --extra-vars "$(getTarget)"
}

function executeScript() {
    printf "Executing ${COMMAND} on ${RED}${ENV_ID}${NC} environment(s) from ${RED}$(getEnvSpecFile)${NC} environment file\n"
    [[ "${COMMAND}" == "stop" || "${COMMAND}" == "restart" ]] && stopInstances
    [[ "${COMMAND}" == "start" || "${COMMAND}" == "restart"  ]] && startInstances
}

function usage() {
  log_always "Usage: $0 -c start -i <initials> --envspec <environment specification file> -v <virtualenv>"
  log_always "Usage: $0 -c stop -i <initials> --envspec <environment specification file> -v <virtualenv>"
  log_always "Usage: $0 -c restart -i <initials> --envspec <environment specification file> -v <virtualenv>"
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
        -c|--command)
            setOption "${arg_key}" "COMMAND" "${optarg}"
            shift # past argument
            ;;
        -i|--initials)
            setOption "${arg_key}" "ENV_ID" "${optarg}"
            shift # past argument
            ;;
        -v|--virtualenv)
            setOption "${arg_key}" "VIRTUAL_ENV" "${optarg}"
            shift # past argument
            ;;
        -x|--extra-vars)
            setOption "${arg_key}" "EXTRA_VARS" "${optarg}"
            shift # past argument
            ;;
        --vault)
            setOption "${arg_key}" "VAULT" "${optarg}"
            shift # past argument
            ;;
      esac
      shift # past argument or value
    done

    [[ -z "${COMMAND}" ]] && {
        log_error "${SCRIPT} requires a command (-c start|stop|restart) argument"
        return 1
    }

    [[ "${COMMAND}" != "start" && "${COMMAND}" != "stop" && "${COMMAND}" != "restart" ]] && {
        log_error "${SCRIPT} only supports start, stop or restart."
        return 1
    }

    [[ -z "${ENV_ID}" ]] && {
        log_error "${SCRIPT} requires an initials (-i <initials>) argument."
         return 1
    }

    [[ -z "${VIRTUAL_ENV}" ]] && {
        log_error "${SCRIPT} requires a virtual environment (-v <ivirtual_env>) argument."
        return 1
    }

    if  [[ "${COMMAND}" == "start" || "${COMMAND}" == "restart" ]]
    then
        haveSecret "vault_password" || {
            log_error "The ${COMMAND} command requires an Ansible vault password"
            storeSecret "vault_password" || {
                log_error "Failed to store the vault password secret."
                return 1
            }
        }

        haveSecret "local_sudo" || {
            log_error "The ${COMMAND} command requires a local sudo password to update /etc/hosts"
            storeSecret "local_sudo"  || {
                log_error "Failed to store the local sudo password secret."
                return 1;
            }
        }
    fi

    if  [[ "${COMMAND}" == "start" || "${COMMAND}" == "restart" || "${COMMAND}" == "stop" ]]
    then
        [[ -f "$(getEnvSpecFile)" ]] || { log_warn "The infra playbooks require an envspec (i.e. '--envspec parameter set to name of a file in ${ANSIBLE_DIR}/varfiles)"; return 1; }
    fi

    return 0
}

wrapper

declare -i status=$?
exit ${status}