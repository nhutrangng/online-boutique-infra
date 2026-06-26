# ADR-006 — NAT Gateway Cost and Availability Strategy

* **Status:** Proposed
* **Date:** 2026-06-23
* **Owners:** Platform / DevOps
* **Decision scope:** Private-subnet egress, environment cost controls, availability trade-off

## Context

EKS worker nodes in private subnets require controlled outbound connectivity for container image pulls, AWS API access, package retrieval, logging, and other approved outbound traffic.

A NAT Gateway per Availability Zone improves resilience but increases recurring cost. The project must keep dev affordable while retaining a production-ready topology.

## Decision

1. NAT Gateway strategy depends on environment.

| Environment          | Default NAT strategy                  | Reason                                                      |
| -------------------- | ------------------------------------- | ----------------------------------------------------------- |
| dev                  | One NAT Gateway                       | Lower recurring cost during learning and functional testing |
| staging              | One NAT Gateway by default            | On-demand environment; cost controlled                      |
| production blueprint | One NAT Gateway per Availability Zone | Avoid a single-AZ egress dependency                         |

2. All NAT Gateways are public NAT Gateways placed in public subnets with Elastic IP addresses.
3. Private subnet route tables must route internet-bound IPv4 traffic through the selected NAT Gateway.
4. Public subnet route tables must route internet-bound IPv4 traffic to the Internet Gateway.
5. Production private subnet in each Availability Zone routes to a NAT Gateway in the same Availability Zone.
6. Dev and staging explicitly accept the availability trade-off of a single NAT Gateway.
7. Add AWS VPC endpoints as a later cost/security optimization, beginning with:

   * S3 Gateway Endpoint.
   * ECR API Interface Endpoint.
   * ECR DKR Interface Endpoint.
   * STS Interface Endpoint.
   * CloudWatch Logs Interface Endpoint.

## Consequences

### Positive

* Dev can run EKS workloads at lower network cost.
* Production blueprint avoids losing all private-subnet egress when one NAT Gateway Availability Zone fails.
* The topology clearly documents where cost and availability trade-offs differ.
* Future VPC endpoints can reduce NAT dependency for AWS service traffic.

### Negative

* Dev is not highly available at the egress layer.
* Production uses more NAT Gateways and costs more.
* Route tables differ by environment and must be tested carefully.

## Acceptance Criteria

### Dev

* One public NAT Gateway exists.
* Private application subnet route tables use that NAT Gateway for default IPv4 egress.
* The availability limitation is documented in the environment README.

### Production Blueprint

* Two NAT Gateways exist, one per Availability Zone.
* Each private application subnet routes through the NAT Gateway in its own Availability Zone.
* No private subnet has a direct default route to the Internet Gateway.

## Review Trigger

## Revisit this ADR when VPC Endpoints cover most AWS service traffic, a regional NAT design is adopted, or staging becomes permanently active.
