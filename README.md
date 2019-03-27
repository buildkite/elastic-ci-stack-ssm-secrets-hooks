# AWS Systems Manager Parameter Store Secrets Hooks

A set of agent hooks that fetch credentials from [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html) for checking out a project.

The following credential types are supported:

- `ssh-agent` for SSH Private Keys
- `git-credential` via git's credential.helper

Used in the [Elastic CI Stack for AWS](https://github.com/buildkite/elastic-ci-stack-for-aws).

## Usage

When run via the agent pre-checkout and pre-exit hook, your builds will check the following Secrets Manager paths:

* `/buildkite/{queue_name}/ssh-private-key`
* `/buildkite/{queue_name}/git-credentials`
* `/buildkite/{queue_name}/{pipeline_slug}/ssh-private-key`
* `/buildkite/{queue_name}/{pipeline_slug}/git-credentials`

You can customize the prefix of `/buildkite` by setting `$BUILDKITE_SSM_SECRETS_PREFIX`.

All of these secrets expect a `SecureString` type.

## Setting Secrets

### Setting SSH Keys for Git Checkouts

This example uploads an ssh key for a git+ssh checkout for a pipeline:

```bash
# generate a deploy key for your project
ssh-keygen -t rsa -b 4096 -f id_rsa_buildkite
pbcopy < id_rsa_buildkite.pub # paste this into your github deploy key

# create a secret with the private key
aws ssm put-parameter \
        --name "/buildkite/<queue-name>/<pipeline-slug>/ssh-private-key" \
        --type SecureString \
        --value "$(cat id_rsa_buildkite)"
```

### Configuring Git Credentials

Here's an example for how you'd configure git credentials for a pipeline, using a [GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/):

```bash
aws ssm put-parameter \
        --name "$buildkite/<queue-name>/<pipeline-slug>/git-credentials" \
        --type SecureString \
        --value "https://<username>:<access-token>@github.com"
```

## License

MIT (see [LICENSE](LICENSE))
