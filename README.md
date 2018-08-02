# AWS Secrets Manager Buildkite Hooks

A set of agent hooks that expose secrets to build steps via [Amazon Secrets Manager](https://aws.amazon.com/secrets-manager/).

Different types of secrets are supported and exposed to your builds in appropriate ways:

- `ssh-agent` for SSH Private Keys
- Environment Variables for strings
- `git-credential` via git's credential.helper

## Installation

The hooks needs to be installed directly in the agent so that secrets can be downloaded before jobs attempt checking out your repository. We are going to assume that buildkite has been installed at `/buildkite`, but this will vary depending on your operating system. Change the instructions accordingly.

```
# clone to a path your buildkite-agent can access
git clone https://github.com/buildkite/elastic-ci-stack-secrets-manager-hooks.git /buildkite/sm_secrets
```

Modify your agent's global hooks (see [https://buildkite.com/docs/agent/v3/hooks#global-hooks](https://buildkite.com/docs/agent/v3/hooks#global-hooks)):

### `${BUILDKITE_ROOT}/hooks/environment`

```bash
if [[ "${SM_SECRETS_HOOKS_ENABLED:-1}" == "1" ]] ; then
  export BUILDKITE_SECRETS_MANAGER_PREFIX="elastic-ci-stack"

  source /buildkite/sm_secrets/hooks/environment
fi
```

### `${BUILDKITE_ROOT}/hooks/pre-exit`

```bash
if [[ "${SM_SECRETS_HOOKS_ENABLED:-1}" == "1" ]] ; then
  export BUILDKITE_SECRETS_MANAGER_PREFIX="elastic-ci-stack"

  source /buildkite/sm_secrets/hooks/pre-exit
fi
```

## Usage

When run via the agent environment and pre-exit hook, your builds will check the following Secrets Manager paths:

* `{prefix}/global/ssh-private-key`
* `{prefix}/global/git-credentials`
* `{prefix}/global/env/{env_name}`
* `{prefix}/pipeline/{pipeline_slug}/ssh-private-key`
* `{prefix}/pipeline/{pipeline_slug}/git-credentials`
* `{prefix}/pipeline/{pipeline_slug}/env/{env_name}`

Inside those secrets, the following keys will be checked:

* `ssh-private-key` is a `SecretBinary` field that contains an ssh key for ssh git checkouts
* `git-credentials` is a `SecretBinary` field that stores git credentials for https git checkouts
* `env/{env_name}` will be a `SecretString` and `{env_name}` will be the environment key that is set

## Uploading Secrets

### SSH Keys

This example uploads an ssh key to the global path.

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

# create a managed secret with the private key
export secrets_manager_prefix="elastic-ci-stack"
aws secretsmanager create-secret \
  --name "${secrets_manager_prefix}/global/ssh-private-key" \
  --secret-binary file://id_rsa_buildkite
```

### Environment

This example stores a custom value for `MY_FAVORITE_LLAMA`, with a value of `they are all good llamas`.

```bash
export secrets_manager_prefix="elastic-ci-stack"
aws secretsmanager create-secret \
  --name "${secrets_manager_prefix}/global/env/MY_FAVORITE_LLAMA" \
  --secret-string "they are all good llamas"
```

### Git credentials

For git over https, you can use a `git-credentials` file with credential urls in the format of:

```
https://user:password@host/path/to/repo
```

```bash
# create a managed secret with the private key
export secrets_manager_prefix="elastic-ci-stack"
aws secretsmanager create-secret \
  --name "${secrets_manager_prefix}/global/git-credentials" \
  --secret-binary "https://user:password@host/path/to/repo"
```

These are then exposed via a [gitcredential helper](https://git-scm.com/docs/gitcredentials) which will download the credentials as needed.

## Configuration

### `SM_SECRETS_HOOKS_ENABLED`

If set to false, off or 0 this disables the secret manager hooks entirely.

### `BUILDKITE_SECRETS_MANAGER_PREFIX`

The prefix to use in secret names, defaults to `elastic-ci-stack`

## License

MIT (see [LICENSE](LICENSE))
