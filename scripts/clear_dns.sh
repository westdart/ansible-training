#!/usr/bin/env bash

########################################################################################################################
# This script works against the AWS Route53 DNS constructs.
# The script takes the following arguments:
# -d|--domain : The DNS domain (without the trainling '.' character).
# -i|--env-id : The environment identifier (usually two alpha-numeric characters)
# -z|--zone   : The specific Route53 zone id to delete
# The script must be executed either with the '-z' argument or both the '-i' and '-d' arguments.
# Also the script has the following useful functions (executed with '-f <function name> <argument list>' as the last
# argument):
# showSummary : Show a summary of all the zones present (or pass a zone-id to get a summary of a specific zone)
# showDetail  : Show detailed information of all the zones present (or pass a zone-id to get a detail on a specific zone)
#######################################################################################################################

DIR=
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || {
    echo "ERROR: Failed to get script directory."
    exit 1
}

ADDITONAL_ARGS_PATTERN='+(-d|--domain|-i|--env-id|-z|--zone)'
ADDITONAL_SWITCHES_PATTERN=''

source "${DIR}/wrapper.sh"

ZONE=
ENV_ID=
DOMAIN=

function allZoneIds() {
    aws route53 list-hosted-zones | jq -r '.HostedZones[] | .Id'
}

function reverseZoneMatches() {
    local zoneId=$1
    local hosts=

    hosts=$(aws route53 list-resource-record-sets --hosted-zone-id "${zoneId}" | jq '.ResourceRecordSets[] | select(.Type=="PTR")' | jq -r '.ResourceRecords[] | .Value')
    [[ $? != 0 ]] && { log_error "Failed to get hosts from zone"; return 1; }
    [[ -z "$hosts" ]] && return 1 # Zone does not match as there are no PTR records
    for host in ${hosts}
    do
        echo $host | grep -q "^${ENV_ID}-"
        [[ $? != 0 ]] && return 1 # Zone does not match as there is a record that does link with the environment
    done
    return 0
}

function getForwardZoneForEnv() {
    aws route53 list-hosted-zones-by-name --output json | jq -r '.HostedZones[] | select(.Name=="'$DOMAIN'.") | .Id'
}

function deleteZone() {
    local hosted_zone_id=$1

    log_info "DELETING: hosted zone ${hosted_zone_id}:"
    showSummary ${hosted_zone_id}

    resourcerecordset=$(aws route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id | jq -c '.ResourceRecordSets[] | select(.Type!="SOA" and .Type!="NS")')

    for record in ${resourcerecordset}
    do
        change_id=$(aws route53 change-resource-record-sets \
          --hosted-zone-id $hosted_zone_id \
          --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":
              '"$record"'
            }]}' \
          --output text \
          --query 'ChangeInfo.Id')
    done

    change_id=$(aws route53 delete-hosted-zone \
      --id $hosted_zone_id \
      --output text \
      --query 'ChangeInfo.Id')
}

function showSummary()
{
    local zoneIds=
    [[ $# == 0 ]] && zoneIds=$(allZoneIds)
    [[ $# != 0 ]] && zoneIds=$@

    local zoneId=
    for zoneId in ${zoneIds}
    do
        hostsStr=""
        hosts=$(aws route53 list-resource-record-sets --hosted-zone-id "${zoneId}" | jq '.ResourceRecordSets[] | select(.Type=="PTR")' | jq -r '.ResourceRecords[] | .Value')

        local host=
        for host in ${hosts}
        do
            hostsStr="${hostsStr}${host},"
        done
        zoneName=$(aws route53 list-resource-record-sets --hosted-zone-id ${zoneId} | jq -r '.ResourceRecordSets[] | select(.Type=="NS").Name')
        if [[ -z "$hosts" ]]
        then
            log_info "${zoneId}: ${zoneName}"
        else
            log_info "${zoneId}: ${zoneName} (${hostsStr::-1})"
        fi
    done

}

function showDetail()
{
    local zoneIds=
    [[ $# == 0 ]] && zoneIds=$(allZoneIds)
    [[ $# != 0 ]] && zoneIds=$@

    local zoneId=
    for zoneId in ${zoneIds}
    do
        aws route53 list-resource-record-sets --hosted-zone-id "${zoneId}"
    done
}

function executeScript() {

    if [[ ! -z "${ZONE}" ]]
    then
        deleteZone ${ZONE}
    elif [[ ! -z "${ENV_ID}" && ! -z "${DOMAIN}" ]]
    then
        local forwardZone=
        forwardZone=$(getForwardZoneForEnv)
        log_info "Forward Zone: ${forwardZone}"

        if [[ ! -z "$forwardZone" ]]
        then
            deleteZone ${forwardZone}
        fi

        log_info "Checking for reverse zones"
        zoneIds=$(allZoneIds)
        for zoneId in ${zoneIds}
        do
            if reverseZoneMatches ${zoneId}
            then
                deleteZone ${zoneId}
            fi
        done
    else
        log_error "Need a zone or env id and domain"
        usage
        return 1
    fi
}


function usage() {
  log_always "Usage:"
  log_always "Delete a specific Zone   : $0 -z <zone>"
  log_always "Delete env related Zones : $0 -i <env-id> -d <domain>"
  log_always "Show a summary of zone(s): $0 -f showSummary [optional: <zone-id>]"
  log_always "Show a detail of zone(s) : $0 -f showDetail [optional: <zone-id>]"
  log_always "Get all zone ids:        : $0 -f allZoneIds"
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
        -i|--env-id)
            setOption "${arg_key}" "ENV_ID" "${optarg}"
            shift # past argument
            ;;
        -d|--domain)
            setOption "${arg_key}" "DOMAIN" "${optarg}"
            shift # past argument
            ;;
        -z|--zone)
            setOption "${arg_key}" "ZONE" "${optarg}"
            shift # past argument
            ;;
      esac
      shift # past argument or value
    done

    return 0
}

wrapper
