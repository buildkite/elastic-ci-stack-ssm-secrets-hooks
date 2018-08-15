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
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/test-org/ssh-private-key-xxxx",
            "Name": "buildkite/test-org/ssh-private-key"
        }
    ]
}
EOF
  cat << EOF > $TMP_DIR/git-credentials-secrets
{
    "SecretList": [
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/test-org/buildkite/test-org/git-credentials-xxxx",
            "Name": "buildkite/test-org/git-credentials"
        }
    ]
}
EOF
  cat << EOF > $TMP_DIR/env-secrets
{
    "SecretList": [
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/tests/test-org/env/MY_FAVORITE_LLAMA-xxxx",
            "Name": "buildkite/test-org/env/MY_FAVORITE_LLAMA"
        }
    ]
}
EOF
  cat << EOF > $TMP_DIR/env-secrets-pipeline
{
    "SecretList": [
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/test-org/env/MY_FAVORITE_LLAMA-xxxx",
            "Name": "buildkite/test-org/env/MY_FAVORITE_LLAMA"
        },
        {
            "ARN": "arn:aws:secretsmanager:us-east-1:xxxxx:secret:buildkite/test-org/pipeline/test/env/MY_FAVORITE_LLAMA-xxx",
            "Name": "buildkite/test-org/pipeline/test/env/MY_FAVORITE_LLAMA"
        }
    ]
}
EOF
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "Load ssh-private-key file from global" {
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_REPO=git@github.com:buildkite/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_ORG_SLUG=test-org

  stub ssh-agent "-s : echo export SSH_AGENT_PID=93799"

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/ssh-secrets" \
    "secretsmanager get-secret-value --secret-id buildkite/test-org/ssh-private-key --query SecretBinary --output text : echo llamas"

  stub ssh-add \
    "- : cat > $TMP_DIR/ssh-add-input ; echo added ssh key"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "ssh-agent (pid 93799)"
  assert_output --partial "added ssh key"
  assert_equal "llamas" "$(cat $TMP_DIR/ssh-add-input)"

  unstub ssh-agent
  unstub ssh-add
  unstub aws
}

@test "Load git-credentials from global into GIT_CONFIG_PARAMETERS" {
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_REPO=https://github.com/buildkite/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_ORG_SLUG=test-org

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/git-credentials-secrets" \
    "secretsmanager get-secret-value --secret-id buildkite/test-org/git-credentials --query SecretBinary --output text : echo https://user:password@host/path/to/repo"

  run bash -c "$PWD/hooks/environment && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Adding git-credentials"
  assert_output --partial "Setting GIT_CONFIG_PARAMETERS"

  run bash -c "$PWD/git-credential-sm-secrets buildkite/test-org/git-credentials"

  assert_success
  assert_output --partial "protocol=https"
  assert_output --partial "host=host"
  assert_output --partial "username=user"
  assert_output --partial "password=password"

  unstub aws
}

@test "Load env from global" {
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_REPO=file://blah/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_ORG_SLUG=test-org

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/env-secrets" \
    "secretsmanager get-secret-value --secret-id buildkite/test-org/env/MY_FAVORITE_LLAMA --query SecretBinary --output text : echo they are all good llamas"

  run bash -c ". $PWD/hooks/environment && echo \$MY_FAVORITE_LLAMA && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "they are all good llamas"

  unstub aws
}

@test "Load env from pipeline over global" {
  export BUILDKITE_PIPELINE_SLUG=test
  export BUILDKITE_REPO=file://blah/llamas.git
  export BUILDKITE_SECRETS_MANAGER_DEBUG=true
  export BUILDKITE_ORG_SLUG=test-org

  stub aws \
    "secretsmanager list-secrets : cat $TMP_DIR/env-secrets-pipeline" \
    "secretsmanager get-secret-value --secret-id buildkite/test-org/env/MY_FAVORITE_LLAMA --query SecretBinary --output text : echo nope" \
    "secretsmanager get-secret-value --secret-id buildkite/test-org/pipeline/test/env/MY_FAVORITE_LLAMA --query SecretBinary --output text : echo they are all good llamas"

  run bash -c ". $PWD/hooks/environment && echo \$MY_FAVORITE_LLAMA && $PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "they are all good llamas"

  unstub aws
}
