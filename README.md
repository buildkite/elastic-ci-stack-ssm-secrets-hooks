# AWS Secrets Manager Agent Hooks

A set of agent hooks that fetch credentials from [Amazon Secrets Manager](https://aws.amazon.com/secrets-manager/) for checking out a project.

The following credential types are supported:

- `ssh-agent` for SSH Private Keys
- `git-credential` via git's credential.helper

## Usage

When run via the agent pre-checkout and pre-exit hook, your builds will check the following Secrets Manager paths:

* `buildkite/{queue_name}/{pipeline_slug}/ssh-private-key`
* `buildkite/{queue_name}/{pipeline_slug}/git-credentials`

Both of these secrets use the `SecretBinary` type.

## Uploading Secrets

### Setting SSH Keys for Git Checkouts

This example uploads an ssh key for a git+ssh checkout for a pipeline:

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

# create a managed secret with the private key
aws secretsmanager create-secret \
  --name "buildkite/<queue-name>/<pipeline-slug>/ssh-private-key" \
  --secret-binary file://id_rsa_buildkite
```

### Configuring Git Credentials

Here's an example for how you'd configure git credentials for a pipeline, using a [GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/):

```bash
aws secretsmanager create-secret \
  --name "buildkite/<queue-name>/<pipeline-slug>/git-credentials" \
  --secret-string "https://<username>:<access-token>@github.com"
```

## License

MIT (see [LICENSE](LICENSE))
