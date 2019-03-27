#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export AWS_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export SSH_AGENT_STUB_DEBUG=/dev/tty

export TMP_DIR=/tmp/run.bats/$$

fake_ssh_private_key() {
  printf -- "-----BEGIN OPENSSH PRIVATE KEY-----\\n%s\\n-----END OPENSSH PRIVATE KEY-----" "$1"
}

setup() {
  mkdir -p $TMP_DIR
  printf "%s\\t%s" "$(fake_ssh_private_key "xxx")" "$(fake_ssh_private_key "yyy")" > $TMP_DIR/ssh-secrets
  printf "%s\\t%s" "/buildkite/my-queue/my-pipeline/git-credentials" "/buildkite/my-queue/git-credentials" > $TMP_DIR/git-secrets
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "Load ssh-private-key file into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=my-pipeline
  export BUILDKITE_REPO=git@github.com:buildkite/llamas.git
  export BUILDKITE_SSM_SECRETS_DEBUG=true
  export BUILDKITE_SSM_SECRETS_PREFIX=/buildkite/my-queue

  stub ssh-agent "-s : echo export SSH_AGENT_PID=93799"

  stub aws \
    "ssm get-parameters --names /buildkite/my-queue/my-pipeline/ssh-private-key /buildkite/my-queue/ssh-private-key --with-decryption --query Parameters[*].Value --output text : cat $TMP_DIR/ssh-secrets"

  stub ssh-add \
    "- : cat > $TMP_DIR/ssh-add-input ; echo added ssh key 1" \
    "- : cat >> $TMP_DIR/ssh-add-input ; echo added ssh key 2"

  run bash -c "$PWD/hooks/pre-command && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 93799)"
  assert_output --partial "added ssh key 1"
  assert_output --partial "added ssh key 2"
  assert_equal "$(cat $TMP_DIR/ssh-add-input)" \
    "$(printf "%s\\n%s" "$(fake_ssh_private_key "xxx")" "$(fake_ssh_private_key "yyy")")"

  unstub ssh-agent
  unstub aws
  unstub ssh-add
}

@test "Load git-credentials into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PIPELINE_SLUG=my-pipeline
  export BUILDKITE_REPO=https://github.com/buildkite/llamas.git
  export BUILDKITE_SSM_SECRETS_DEBUG=true
  export BUILDKITE_SSM_SECRETS_PREFIX=/buildkite/my-queue

  stub aws \
    "ssm get-parameters --names /buildkite/my-queue/my-pipeline/git-credentials /buildkite/my-queue/git-credentials --query Parameters[*].Name --output text : cat $TMP_DIR/git-secrets" \
    "ssm get-parameters --names /buildkite/my-queue/my-pipeline/git-credentials} --with-decryption --query Parameters[*].Value --output text : echo https://user:password@host/path"

  run bash -c "$PWD/hooks/pre-command && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials"
  assert_output --partial "Setting GIT_CONFIG_PARAMETERS"

  run bash -c "$PWD/git-credential-sm-secrets /buildkite/my-queue/my-pipeline/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub aws
}
