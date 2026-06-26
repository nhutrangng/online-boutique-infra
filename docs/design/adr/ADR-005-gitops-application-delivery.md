# ADR-005 — GitOps Application Delivery Model

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps
* **Decision scope:** Boundary between Terraform, Kubernetes, GitOps, and application deployment

## Context

Terraform is responsible for cloud infrastructure lifecycle. Kubernetes application manifests change more frequently and need a different reconciliation and rollback model.

Managing all Online Boutique Deployments, Services, Ingresses, HPA policies, and application configuration directly from the infrastructure Terraform repository would tightly couple cloud changes with application release changes.

## Decision

1. Separate infrastructure delivery from application delivery.

```text
Infrastructure repository
  └── Terraform:
      S3 state, IAM, VPC, EKS, ECR, security foundation,
      EKS access, node groups, CloudWatch foundations

GitOps repository
  └── Kubernetes:
      Namespaces, Deployments, Services, Ingress,
      HPA, NetworkPolicy, Helm values, application configuration
```

2. Use Argo CD as the target GitOps reconciler running inside the EKS cluster.
3. Terraform creates AWS-side prerequisites only:

   * EKS cluster.
   * EKS access entries.
   * ECR repositories.
   * IAM roles and Pod Identity associations required by platform controllers.
   * CloudWatch and logging foundations.
4. GitOps owns all Online Boutique workload manifests.
5. GitOps also owns Helm release configuration for in-cluster controllers, including the AWS Load Balancer Controller.
6. Terraform exposes only the minimum outputs needed by bootstrap or GitOps:

   * EKS cluster name.
   * Region.
   * OIDC / Pod Identity role references where required.
   * ECR repository URLs.
7. Initial GitOps bootstrap is a documented, controlled administrative action.
8. After bootstrap, all application changes are made through pull requests to the GitOps repository and reconciled by Argo CD.

## Environment Layout

```text
gitops/
├── clusters/
│   ├── dev/
│   ├── staging/
│   └── production/
│
├── platform/
│   ├── aws-load-balancer-controller/
│   ├── external-secrets/
│   └── observability/
│
└── applications/
    └── online-boutique/
        ├── base/
        └── overlays/
            ├── dev/
            ├── staging/
            └── production/
```

## Consequences

### Positive

* Application releases do not require Terraform state changes.
* Kubernetes drift is continuously reconciled by GitOps.
* Application rollback uses Git revision rollback rather than Terraform rollback.
* Infrastructure and workload permissions remain separated.
* The platform can later support multiple applications without changing Terraform root-module boundaries.

### Negative

* A second repository and delivery workflow must be maintained.
* Initial GitOps bootstrap is an additional operational step.
* Engineers must understand both Terraform and GitOps ownership boundaries.

## Non-Goals

Terraform must not own:

* Online Boutique Deployments.
* Application Services.
* Application Ingress objects.
* HPA policies.
* Application ConfigMaps and Secrets.
* Day-to-day Helm application releases.

## Acceptance Criteria

* A Terraform change is not needed for a normal Online Boutique application release.
* A GitOps pull request is sufficient to change image tags, replicas, manifests, and Helm values.
* Terraform remains the authoritative source for AWS infrastructure.
* Argo CD becomes the authoritative reconciliation mechanism for Kubernetes application state.

## Review Trigger

## Revisit this ADR when introducing a private-only EKS endpoint, self-hosted runners, a multi-cluster fleet, or an internal platform catalog.
