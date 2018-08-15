# AWS Secrets Manager Buildkite Hooks

A set of agent hooks that expose secrets to build steps via [Amazon Secrets Manager](https://aws.amazon.com/secrets-manager/).

Different types of secrets are supported and exposed to your builds in appropriate ways:

- `ssh-agent` for SSH Private Keys
- Environment Variables for strings
- `git-credential` via git's credential.helper

## Usage

When run via the agent environment and pre-exit hook, your builds will check the following Secrets Manager paths:

* `buildkite/{org_slug}/ssh-private-key`
* `buildkite/{org_slug}/git-credentials`
* `buildkite/{org_slug}/env/{env_name}`
* `buildkite/{org_slug}/pipeline/{pipeline_slug}/ssh-private-key`
* `buildkite/{org_slug}/pipeline/{pipeline_slug}/git-credentials`
* `buildkite/{org_slug}/pipeline/{pipeline_slug}/env/{env_name}`

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
aws secretsmanager create-secret \
  --name "/buildkite/my-org/ssh-private-key" \
  --secret-binary file://id_rsa_buildkite
```

### Environment

This example stores a custom value for `MY_FAVORITE_LLAMA`, with a value of `they are all good llamas`.

```bash
aws secretsmanager create-secret \
  --name "/buildkite/my-org/env/MY_FAVORITE_LLAMA" \
  --secret-string "they are all good llamas"
```

### Git credentials

For git over https, you can use a `git-credentials` file with credential urls in the format of:

```
https://user:password@host/path/to/repo
```

```bash
# create a managed secret with the private key
aws secretsmanager create-secret \
  --name "/buildkite/my-org/git-credentials" \
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
