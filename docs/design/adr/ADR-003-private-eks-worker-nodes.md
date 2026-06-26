# ADR-003 — Private EKS Worker Nodes and Public Application Entry

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps
* **Decision scope:** VPC subnet placement, EKS endpoint access, public exposure

## Context

Online Boutique is a public web application, but Kubernetes nodes and internal services must not be directly reachable from the internet.

The platform must separate public entry points from private workload execution while preserving a practical administration path during Version 1.

## Decision

1. Each environment VPC spans two Availability Zones.
2. Each Availability Zone contains:

   * One public subnet.
   * One private application subnet.
3. Internet-facing Application Load Balancers are created only in public subnets.
4. NAT Gateways are created only in public subnets.
5. EKS managed node groups run only in private subnets.
6. Kubernetes Pods run on nodes in private subnets.
7. EKS worker nodes must not receive public IPv4 addresses.
8. Only the Online Boutique `frontend` service is exposed through an internet-facing ALB.
9. All internal Online Boutique services use Kubernetes `ClusterIP` networking only.
10. Terraform does not create a standalone ALB. The AWS Load Balancer Controller creates and manages ALBs from approved Kubernetes Ingress resources.
11. EKS API endpoint configuration for Version 1:

```text
private endpoint access = enabled
public endpoint access  = enabled temporarily
public CIDRs            = explicitly approved administrator CIDRs only
```

12. GitHub Actions does not require direct access to the Kubernetes API. Terraform CI/CD manages AWS infrastructure through AWS APIs only.
13. Application deployment is reconciled from inside the cluster through GitOps after bootstrap.

## Network Flow

```text
Internet
  ↓
Internet Gateway
  ↓
Public ALB
  ↓
Kubernetes Ingress
  ↓
frontend Service
  ↓
Internal Online Boutique services
  ↓
Redis cart
```

Outbound flow:

```text
Private node / Pod
  ↓
Private subnet route table
  ↓
NAT Gateway or approved VPC Endpoint
  ↓
ECR / S3 / CloudWatch / Internet
```

## Consequences

### Positive

* Worker nodes and Pods have no direct inbound route from the public internet.
* Public exposure is concentrated at the ALB security group and Ingress layer.
* Internal services are not accidentally made internet-facing.
* The design supports future NetworkPolicy, Pod Identity, service mesh, and private-only EKS API access.

### Negative

* Private workloads require controlled outbound connectivity through NAT Gateways or VPC Endpoints.
* Initial cluster bootstrap requires an approved administrator access path.
* Network design is more expensive than placing EKS nodes in public subnets.

## Acceptance Criteria

* Two public subnets and two private subnets exist across two Availability Zones.
* EKS node-group subnet IDs refer only to private subnets.
* No worker node has a public IP address.
* Public ALB subnets have a route to the Internet Gateway.
* Private application subnets do not have a direct route to the Internet Gateway.
* Only the approved ALB security group permits public web ingress.
* No internal application Service uses `LoadBalancer` type without an approved architecture change.

## Review Trigger

## Revisit this ADR when the cluster API endpoint becomes private-only, a self-hosted runner is introduced, or the project adopts centralized ingress/WAF.
