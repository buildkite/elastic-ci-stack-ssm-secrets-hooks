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

For those secrets, the following types will be expected:

* `ssh-private-key` is a `SecretBinary` that contains an ssh key for ssh git checkouts
* `git-credentials` is a `SecretBinary` that stores git credentials for https git checkouts
* `env/{env_name}` will be a `SecretString` and `{env_name}` will be the environment key that is set

## Uploading Secrets

### Setting SSH Keys for Git Checkouts

This example uploads an ssh key that would be used globally across your organization.

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

# create a managed secret with the private key
aws secretsmanager create-secret \
  --name "buildkite/my-org/ssh-private-key" \
  --secret-binary file://id_rsa_buildkite
```

### Setting Environment Variables

Here's an example of how you would set an env of `MY_FAVORITE_LLAMA`, with a value of `they are all good llamas` for all builds across all pipelines.

```bash
aws secretsmanager create-secret \
  --name "buildkite/my-org/env/MY_FAVORITE_LLAMA" \
  --secret-string "they are all good llamas"
```

### Configuring Git Credentials

Here's an example for how you'd configure a global git credential for the entire stack, using a [GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/):

```bash
aws secretsmanager create-secret \
  --name "buildkite/<org-slug>/git-credentials" \
  --secret-string "https://<username>:<access-token>@github.com"
```

You can also override it a per-pipeline basis:

```
aws secretsmanager create-secret \
  --name "buildkite/<org-slug>/pipeline/<pipeline-slug>/git-credentials" \
  --secret-string "https://<username>:<access-token>@github.com"
```

## License

MIT (see [LICENSE](LICENSE))
