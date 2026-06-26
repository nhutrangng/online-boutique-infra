# ADR-004 — GitHub Actions OIDC for Terraform CI/CD

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps
* **Decision scope:** CI/CD authentication, AWS IAM trust, deployment authorization

## Context

Terraform CI/CD must access AWS without long-lived AWS access keys stored in GitHub Secrets.

The deployment path must distinguish read-only planning from mutating apply operations and must protect staging and production from accidental execution.

## Decision

1. Configure GitHub Actions as an AWS IAM OpenID Connect identity provider.
2. GitHub Actions receives temporary AWS credentials by assuming IAM roles through OIDC.
3. No long-lived AWS access key or secret key may be stored in GitHub Secrets.
4. Create separate CI/CD roles:

```text
github-terraform-plan
github-terraform-apply-dev
github-terraform-apply-staging
github-terraform-apply-production
```

5. The `github-terraform-plan` role is read-only and can read only approved Terraform state prefixes.
6. Apply roles may mutate only their own environment resources and their own state prefix.
7. Production apply is permitted only when all conditions are true:

```text
repository = approved infrastructure repository
branch     = main
environment = production
GitHub Environment approval = completed
```

8. Pull requests from forks run `fmt`, `validate`, linting, and static security checks only. They must not receive AWS credentials or read Terraform state.
9. CI/CD roles must use restrictive OIDC trust-policy conditions:

   * `aud` must equal `sts.amazonaws.com`.
   * `sub` must match the approved repository and GitHub Environment.
   * Production trust must not accept arbitrary branches.
10. Terraform state permissions include the matching `.tflock` object required for S3 native locking.

## Deployment Model

```text
Feature branch
  ↓
Pull request
  ↓
fmt + validate + lint + policy + plan
  ↓
Peer review
  ↓
Merge to main
  ↓
Apply dev

Release approval
  ↓
Apply staging / production through protected GitHub Environment
```

## Consequences

### Positive

* No static cloud credentials are copied into GitHub.
* Every AWS action is associated with an IAM role session and GitHub workflow context.
* Production access is separated from dev access.
* Compromise of a dev apply role does not automatically grant production access.

### Negative

* IAM trust policies are more complex than static credentials.
* GitHub Environment protection rules must be maintained.
* OIDC claims and role permissions require testing whenever repository naming or workflow structure changes.

## Acceptance Criteria

* GitHub Secrets contain no AWS access key or AWS secret access key.
* `id-token: write` is granted only to jobs that need AWS federation.
* Plan and apply roles are separate.
* Production apply requires GitHub Environment approval.
* CI/CD roles can access only their permitted S3 state prefixes.
* CI/CD can create and remove matching `.tflock` objects for its assigned state prefix.

## Review Trigger

Revisit this ADR when introducing self-hosted runners, multiple repositories, multiple AWS accounts, or release automation beyond GitHub Actions.
