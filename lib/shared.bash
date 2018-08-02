#!/bin/bash

sm() {
  # if ! aws help | grep "secretsmanager" ; then
  #   echo "Your aws-cli doesn't support secretsmanager" >&2
  #   exit 1
  # fi
  aws secretsmanager "$@"
}

sm_secret_names() {
  sm list-secrets | grep -i '^[[:space:]]*"Name":' | cut -d'"' -f 4
}

sm_secret_get() {
  local secret_id="$1"
  local query="${2:-SecretBinary}"

  sm get-secret-value \
    --secret-id "${secret_id}" \
    --query "${query}" \
    --output text
}

add_ssh_private_key_to_agent() {
  local ssh_key="$1"

  if [[ -z "${SSH_AGENT_PID:-}" ]] ; then
    echo "Starting an ephemeral ssh-agent" >&2;
    eval "$(ssh-agent -s)"
  fi

  echo "Loading ssh-key into ssh-agent (pid ${SSH_AGENT_PID:-})" >&2;
  echo "$ssh_key" | env SSH_ASKPASS="/bin/false" ssh-add -
}

in_array() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}
