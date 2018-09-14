#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# export AWS_STUB_DEBUG=/dev/tty
# export SSH_ADD_STUB_DEBUG=/dev/tty
# export SSH_AGENT_STUB_DEBUG=/dev/tty

export TMP_DIR=/tmp/run.bats/$$

setup() {
  mkdir -p $TMP_DIR
  cat << EOF > $TMP_DIR/ssh-secrets
{
    "SecretList": [
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/my-org/my-queue/my-pipeline/ssh-private-key-xxxx",
            "Name": "buildkite/my-org/my-queue/my-pipeline/ssh-private-key"
        }
    ]
}
EOF
  cat << EOF > $TMP_DIR/git-credentials-secrets
{
    "SecretList": [
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/my-org/my-queue/my-pipeline/git-credentials-xxxx",
            "Name": "buildkite/my-org/my-queue/my-pipeline/git-credentials"
        }
    ]
}
EOF
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "Load ssh-private-key file into ssh-agent" {
  export BUILDKITE_PIPELINE_SLUG=my-pipeline
  export BUILDKITE_REPO=git@github.com:buildkite/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_SECRETS_PREFIX=buildkite/my-org/my-queue

  stub ssh-agent "-s : echo export SSH_AGENT_PID=93799"

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/ssh-secrets" \
    "secretsmanager get-secret-value --secret-id buildkite/my-org/my-queue/my-pipeline/ssh-private-key --query SecretBinary --output text : echo llamas"

  stub ssh-add \
    "- : cat > $TMP_DIR/ssh-add-input ; echo added ssh key"

  run bash -c "$PWD/hooks/pre-command && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 93799)"
  assert_output --partial "added ssh key"
  assert_equal "llamas" "$(cat $TMP_DIR/ssh-add-input)"

  unstub ssh-agent
  unstub ssh-add
  unstub aws
}

@test "Load git-credentials into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PIPELINE_SLUG=my-pipeline
  export BUILDKITE_REPO=https://github.com/buildkite/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_SECRETS_PREFIX=buildkite/my-org/my-queue

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/git-credentials-secrets" \
    "secretsmanager get-secret-value --secret-id buildkite/my-org/my-queue/my-pipeline/git-credentials --query SecretBinary --output text : echo https://user:password@host/path/to/repo"

  run bash -c "$PWD/hooks/pre-command && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials"
  assert_output --partial "Setting GIT_CONFIG_PARAMETERS"

  run bash -c "$PWD/git-credential-sm-secrets buildkite/my-org/my-queue/my-pipeline/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub aws
}
