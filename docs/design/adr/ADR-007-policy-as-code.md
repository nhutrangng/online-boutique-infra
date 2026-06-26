# ADR-007 — Policy-as-Code Enforcement for Terraform

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps / Security
* **Decision scope:** Terraform governance, pull-request controls, preventive security policy

## Context

Terraform validation confirms syntax and internal consistency, but it does not enforce organization-specific security, cost, ownership, and environment rules.

The project needs policies that inspect the actual Terraform execution plan before infrastructure is applied.

## Decision

1. Use Open Policy Agent policy written in Rego.
2. Use Conftest in CI/CD to evaluate the JSON output of Terraform plans.
3. Treat policy code as production code:

   * Version-controlled.
   * Peer-reviewed.
   * Tested.
   * Owned by platform/security reviewers.
4. A policy denial blocks merge and blocks apply.
5. Security scanners remain separate quality gates:

   * `terraform fmt`.
   * `terraform validate`.
   * `tflint`.
   * Checkov or Trivy configuration scanning.
   * OPA / Conftest policy evaluation.
6. Initial enforced policies:

| Policy ID | Rule                                                                                                                              |
| --------- | --------------------------------------------------------------------------------------------------------------------------------- |
| P001      | Managed resources require Project, Environment, Owner, ManagedBy, Component, and CostCenter tags where tags are supported         |
| P002      | S3 buckets must block public access and use encryption                                                                            |
| P003      | Security groups must not expose SSH or RDP to `0.0.0.0/0`                                                                         |
| P004      | Public inbound web access is allowed only for approved ALB security groups on TCP 80 and 443                                      |
| P005      | Production plans may not delete managed resources without an approved break-glass workflow                                        |
| P006      | Terraform state bucket protections must remain enabled: versioning, KMS encryption, public-access block, and lockfile permissions |
| P007      | Resources must use approved AWS regions only                                                                                      |

7. Policy violations are categorized:

```text
deny = blocks merge/apply
warn = visible in PR but does not block
```

8. Every policy requires:

   * A Rego rule.
   * A passing test fixture.
   * A failing test fixture.
   * Documentation explaining the reason and remediation.
9. Policy exceptions must not be bypassed by editing the policy in the same pull request as the violating infrastructure change.
10. Production exceptions require a separate approved change and an expiration/review date.

## CI/CD Flow

```text
terraform fmt -check
  ↓
terraform validate
  ↓
tflint + configuration security scanning
  ↓
terraform plan -out=tfplan
  ↓
terraform show -json tfplan > tfplan.json
  ↓
conftest test tfplan.json --policy policies/terraform
  ↓
PR review
  ↓
apply after merge and approval
```

## Consequences

### Positive

* Common security and governance mistakes are caught before apply.
* Rules are transparent, reviewable, and reproducible.
* Policy decisions are based on planned infrastructure, not only raw `.tf` source files.
* The project demonstrates preventive controls rather than after-the-fact auditing.

### Negative

* Initial policy development takes time.
* Policies must evolve as modules and architecture evolve.
* Incorrect policies can block legitimate changes, so test coverage is required.

## Initial Repository Layout

```text
policies/
└── terraform/
    ├── rego/
    │   ├── required_tags.rego
    │   ├── s3_public_access.rego
    │   ├── security_group_ingress.rego
    │   ├── production_destroy.rego
    │   └── approved_regions.rego
    ├── tests/
    │   ├── required_tags_test.rego
    │   ├── s3_public_access_test.rego
    │   └── ...
    └── README.md
```

## Review Trigger

Revisit this ADR when policy enforcement expands to Kubernetes admission control, AWS Organizations SCPs, cost policies, or centralized policy distribution.
