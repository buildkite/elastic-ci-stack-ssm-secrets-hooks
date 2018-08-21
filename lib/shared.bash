#!/bin/bash

sm() {
  aws secretsmanager "$@"
}

sm_secret_names() {
  sm list-secrets | grep -i '^[[:space:]]*"Name":' | cut -d'"' -f 4
}

sm_secret_get() {
  local secret_id="$1"
  local query="${2:-SecretBinary}"
  local secrets=$(sm get-secret-value --secret-id "${secret_id}" --query "${query}" --output text)
  if [[ ${query} == 'SecretString' ]]; then
    # Secret String can contain multiple key: value pairs
    # Iterate over all of them and export each one individually.
    local exports=($(echo $secrets | jq -r 'to_entries[]|"\(.key),\(.value)"'|sed -e 's/,/=/g'))
    for e in "${exports[@]}"; do
        if [[ ${e} = 'None' ]]; then
            echo "+++ :warning: Failed to get secret ${secret_id}" >&2
            exit 1
        fi
        local secret_name=$(echo ${e} |awk -F"=" {'print $1'})
        local secret_value=$(echo ${e} |awk -F"=" {'print $2'})
        #debug "Exporting ${secret_name} as ${secret_value}"
        eval export ${e}
    done
  elif [[ ${query} == 'SecretBinary' ]]; then
    # SecretBinary can only return a single string
    # decode the response, and output it.
    echo ${secrets} |base64 --decode
  fi
}

add_ssh_private_key_to_agent() {
  local ssh_key="$1"

  if [[ -z "${SSH_AGENT_PID:-}" ]] ; then
    echo "Starting an ephemeral ssh-agent" >&2;
    eval "$(ssh-agent -s)"
  fi

  echo "Loading ssh-key into ssh-agent (pid ${SSH_AGENT_PID:-})" >&2;
  echo "$ssh_key" | env DISPLAY=:0 SSH_ASKPASS="/bin/false" ssh-add -
}

in_array() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}
