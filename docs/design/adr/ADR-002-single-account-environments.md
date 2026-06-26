# ADR-002 — Environment Separation Strategy

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps
* **Decision scope:** Terraform state, environment isolation, deployment permissions

## Context

The platform must support `dev`, `staging`, and `production` while keeping blast radius small, controlling costs, and making infrastructure changes easy to review.

Version 1 uses one AWS account. Therefore, environment isolation must be implemented through separate VPCs, Terraform root modules, remote-state keys, IAM roles, tags, and protected CI/CD paths.

## Decision

1. Use one AWS account for Version 1.
2. Create one VPC per environment.
3. Use separate Terraform root modules and separate S3 state objects for each environment and infrastructure layer.
4. Do not use Terraform workspaces for environment separation.
5. Do not allow an environment to read another environment's Terraform state.
6. Use the following state topology:

```text
global/bootstrap-state
global/identity

env/dev/network
env/dev/security-foundation
env/dev/platform
env/dev/compute

env/staging/network
env/staging/security-foundation
env/staging/platform
env/staging/compute

env/production/network
env/production/security-foundation
env/production/platform
env/production/compute
```

7. Every resource must include these baseline tags:

```text
Project
Environment
Owner
ManagedBy
Component
CostCenter
```

8. Deployment permissions are environment-specific:

| Environment | Intended use                              | Apply path                                                                  |
| ----------- | ----------------------------------------- | --------------------------------------------------------------------------- |
| dev         | Functional validation and experimentation | CI/CD after PR merge; controlled local apply allowed during early lab phase |
| staging     | Release/integration validation            | CI/CD only                                                                  |
| production  | Protected production-ready blueprint      | CI/CD only, main branch, approval required                                  |

## Consequences

### Positive

* A failed apply in `dev/network` cannot directly corrupt `production/platform`.
* Each layer has a small and understandable blast radius.
* IAM permissions can be scoped by environment and S3 state prefix.
* Destroying the dev environment does not affect staging or production.
* Pull-request plans are easier to review because each change is limited to one layer.

### Negative

* More backend configuration files must be maintained.
* Shared changes may require multiple pull requests or coordinated applies.
* Outputs must be deliberately exposed through `terraform_remote_state`.
* Cross-environment promotion is configuration-driven, not automatic state sharing.

## Implementation Rules

* Every root module owns one `backend.tf` and one `backend.hcl`.
* All environment states use the same approved S3 state bucket and KMS key.
* Only the state `key` differs between root modules.
* State keys follow this format:

```text
online-boutique/<environment>/<layer>/terraform.tfstate
```

* Resource naming follows this format:

```text
<project>-<environment>-<component>
```

## Review Trigger

## Revisit this ADR when the project moves to a multi-account landing zone, centralized networking, or separate AWS accounts for production.
