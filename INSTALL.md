# Installation

The hooks needs to be installed directly in the agent so that secrets can be downloaded before jobs attempt checking out your repository. We are going to assume that buildkite has been installed at `/buildkite`, but this will vary depending on your operating system. Change the instructions accordingly.

```
# clone to a path your buildkite-agent can access
git clone https://github.com/buildkite/elastic-ci-stack-secrets-manager-hooks.git /buildkite/sm_secrets
```

Modify your agent's global hooks (see [https://buildkite.com/docs/agent/v3/hooks#global-hooks](https://buildkite.com/docs/agent/v3/hooks#global-hooks)):

## `${BUILDKITE_ROOT}/hooks/environment`

```bash
if [[ "${SM_SECRETS_HOOKS_ENABLED:-1}" == "1" ]] ; then
  source /buildkite/sm_secrets/hooks/environment
fi
```

## `${BUILDKITE_ROOT}/hooks/pre-exit`

```bash
if [[ "${SM_SECRETS_HOOKS_ENABLED:-1}" == "1" ]] ; then
  source /buildkite/sm_secrets/hooks/pre-exit
fi
```
