#!/bin/bash

ssm_secret_get() {
  local path="$1"

  aws ssm get-parameters \
      --names "$path}" \
      --with-decryption \
      --query Parameters[*].Value \
      --output text
}

add_ssh_private_key_to_agent() {
  local ssh_key="$1"

  if [[ -z "${SSH_AGENT_PID:-}" ]] ; then
    echo "Starting an ephemeral ssh-agent" >&2;
    eval "$(ssh-agent -s)"
  fi

  echo "Loading ssh-key into ssh-agent (pid ${SSH_AGENT_PID:-})" >&2;
  echo "$ssh_key"
  echo "$ssh_key" | env SSH_ASKPASS="/bin/false" ssh-add -
}
