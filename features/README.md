# Cucumber integration features

The default suite (run by `rake jenkins_cucumber` via `test.sh`) exercises the
API against a local Conjur brought up by `docker-compose`.

## Cloud authenticator features

`authn_iam.feature`, `authn_azure.feature`, and `authn_gcp.feature` are **live
integration tests** for the AWS IAM / Azure / GCP authenticators. They are
tagged `@authn_iam` / `@authn_azure` / `@authn_gcp` and are **excluded from the
default run** (see `Rakefile`), because they only pass on the matching cloud
provider's infrastructure.

### How they run in CI

They are gated behind Jenkins boolean params `RUN_AWS_TESTS` / `RUN_AZURE_TESTS`
/ `RUN_GCP_TESTS` (default `false`; enabled by the daily cron). When a flag is
set, `test.sh` runs only that authenticator's feature against a real Conjur
(with `CONJUR_AUTHENTICATORS` including the cloud authenticators) plus the real
cloud metadata/STS service:

- **AWS IAM** — runs on the standard `ExecutorV2` agent, which is itself in AWS
  and carries an instance profile. The stage derives the caller identity with
  `aws sts get-caller-identity` and passes `AWS_ACCOUNT_ID` / `AWS_ROLE_NAME`;
  the Conjur host id is `<account-id>/<role-name>` (authn-iam matches the host
  to the signing role). `new_from_iam` signs a real STS `GetCallerIdentity`
  request.
- **Azure** — runs on an `AzureExecutorV2` agent. `summon -e azure` injects
  `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, and
  `USER_ASSIGNED_IDENTITY_CLIENT_ID`. `new_from_azure` fetches a JWT from the
  real Azure IMDS (`169.254.169.254`); the feature derives the `provider-uri`
  from that token's `iss` claim and annotates the host with the
  subscription-id / resource-group restrictions.
- **GCP** — GCP agents lack a Docker runtime, so the flow is split:
  `ci/get_gcp_token.sh` fetches a real identity token on a `GcpExecutorV2`
  agent, Jenkins stashes it, and the test runs on the AWS agent with the token
  passed via `GCP_ID_TOKEN` (and `GCP_PROJECT_ID` for the host's
  `authn-gcp/project-id` annotation). `new_from_gcp` exchanges that pre-fetched
  token via the serviceless `authn-gcp` endpoint, bypassing the metadata service.

`test.sh` forwards the cloud env vars into the tester container and clears
`HTTP(S)_PROXY` / sets `NO_PROXY` so the link-local metadata endpoints are
reachable directly.

### Running one locally

You must be on (or have credentials for) the relevant cloud. For example, on an
AWS host with an appropriate instance profile / credentials:

```sh
RUN_AWS_TESTS=true ./test.sh
```

For GCP, fetch a token first (on a GCP host), then point the test at it:

```sh
./ci/get_gcp_token.sh data/test/gcp-apps/test-app cucumber gcp-ctx
GCP_ID_TOKEN="$(cat gcp-ctx/token)" RUN_GCP_TESTS=true ./test.sh
```

### CI infrastructure these depend on

The cloud stages authenticate against real provider infrastructure, so they
rely on the following being in place (all currently provisioned in the
Conjur-Enterprise CI):

1. `AzureExecutorV2` / `GcpExecutorV2` InfraPool agent types, plus the standard
   AWS `ExecutorV2` agent (used for AWS IAM and to run the GCP test).
2. The `!var` references in `secrets.yml` (`ci/azure/...`) resolvable from the
   CI Conjur vault, so `summon -e azure` can supply the `AZURE_*` /
   `USER_ASSIGNED_IDENTITY_CLIENT_ID` values.
3. Cloud identities matching how each feature builds its Conjur host:
   - **AWS**: the executor's instance-profile role (host id `<account>/<role>`,
     derived at runtime).
   - **Azure**: the managed identity in the given subscription / resource-group.
   - **GCP**: the `GcpExecutorV2` agent's service account, mapped to
     `data/test/gcp-apps/test-app` via the `authn-gcp/project-id` annotation.

If any of these change, a stage may fail with an opaque `401`; `test.sh` dumps
the Conjur server log on cloud-test failure so the precise reason is visible.
