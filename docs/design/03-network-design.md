# Network Design — Online Boutique AWS EKS Platform

* **Status:** Proposed
* **Region:** ap-southeast-2
* **Environment covered:** dev
* **Owners:** Platform / DevOps
* **Related ADRs:** ADR-002, ADR-003, ADR-006

## 1. Design Objectives

This network design must:

* Keep EKS worker nodes and application Pods private.
* Expose only the public application entry point through an internet-facing ALB.
* Span two Availability Zones.
* Reserve enough IP address space for EKS nodes, Pods, future scaling, and future services.
* Keep dev cost controlled while preserving a production-ready topology.
* Avoid CIDR overlap between dev, staging, and production.
* Support separate Terraform state and lifecycle for network, platform, and compute layers.

## 2. Environment CIDR Allocation

| Environment |       VPC CIDR | Status                               |
| ----------- | -------------: | ------------------------------------ |
| dev         | `10.20.0.0/16` | Active deployment environment        |
| staging     | `10.21.0.0/16` | Reserved production-like environment |
| production  | `10.22.0.0/16` | Reserved protected environment       |

Each environment owns an independent VPC. CIDR ranges must never overlap.

## 3. Availability Zone Selection

The two selected Availability Zones are recorded after querying the AWS account.

| Logical Zone | AWS Zone Name                   | AWS Zone ID                     |
| ------------ | ------------------------------- | ------------------------------- |
| AZ-1         | `<replace-after-aws-cli-check>` | `<replace-after-aws-cli-check>` |
| AZ-2         | `<replace-after-aws-cli-check>` | `<replace-after-aws-cli-check>` |

Terraform receives the selected AZ names through environment configuration. The design refers to them only as `AZ-1` and `AZ-2`.

## 4. Dev Subnet Plan

| Tier             | AZ   |            CIDR | Purpose                                              | Created in V1 |
| ---------------- | ---- | --------------: | ---------------------------------------------------- | ------------- |
| public           | AZ-1 |  `10.20.0.0/24` | NAT Gateway, internet-facing ALB                     | Yes           |
| public           | AZ-2 |  `10.20.1.0/24` | Internet-facing ALB capacity and multi-AZ resilience | Yes           |
| private-cluster  | AZ-1 |  `10.20.2.0/24` | EKS control-plane ENIs                               | Yes           |
| private-cluster  | AZ-2 |  `10.20.3.0/24` | EKS control-plane ENIs                               | Yes           |
| private-workload | AZ-1 | `10.20.16.0/20` | EKS worker nodes, Pods, platform controllers         | Yes           |
| private-workload | AZ-2 | `10.20.32.0/20` | EKS worker nodes, Pods, platform controllers         | Yes           |
| reserved-data    | AZ-1 | `10.20.48.0/20` | Future RDS, ElastiCache, EFS, private data services  | No            |
| reserved-data    | AZ-2 | `10.20.64.0/20` | Future RDS, ElastiCache, EFS, private data services  | No            |

## 5. Rationale for Subnet Sizing

### Public subnets

`/24` public subnets are reserved for ALB and NAT Gateway resources. They are intentionally larger than the immediate development requirement to allow future load balancer growth and avoid subnet exhaustion.

### Private cluster subnets

`/24` private cluster subnets are dedicated to Amazon EKS-created control-plane ENIs. They are isolated from node and Pod IP consumption.

### Private workload subnets

`/20` private workload subnets are used by managed node groups and Kubernetes Pods. These are larger because Pods receive VPC IP addresses through the Amazon VPC CNI.

### Reserved data subnets

Data subnets are reserved but not created in Version 1. This prevents future stateful services from forcing a VPC CIDR redesign.

## 6. Routing Design

### Internet Gateway

One Internet Gateway is attached to the VPC.

```text
VPC
└── Internet Gateway
```

### Dev NAT Strategy

Dev uses one NAT Gateway in the public subnet of AZ-1.

```text
Private subnet AZ-1 ─┐
                     ├── NAT Gateway AZ-1 ── Internet Gateway ── Internet
Private subnet AZ-2 ─┘
```

This is an intentional cost optimization. It is an accepted single point of egress failure for dev.

### Route Table Matrix

| Route table        | Associated subnets                                    | `0.0.0.0/0` destination | Purpose                               |
| ------------------ | ----------------------------------------------------- | ----------------------- | ------------------------------------- |
| `rt-public`        | public AZ-1, public AZ-2                              | Internet Gateway        | ALB and NAT public connectivity       |
| `rt-private-dev`   | private-cluster AZ-1/AZ-2, private-workload AZ-1/AZ-2 | NAT Gateway in AZ-1     | Private outbound connectivity for dev |
| `rt-reserved-data` | Reserved only; not created in V1                      | None                    | Future data-tier design               |

All route tables retain the implicit VPC-local route.

Private subnets must never have a direct default route to the Internet Gateway.

## 7. Production Topology Difference

Production retains the same subnet pattern but uses one NAT Gateway per Availability Zone.

```text
Private subnets AZ-1 → NAT Gateway AZ-1 → Internet Gateway
Private subnets AZ-2 → NAT Gateway AZ-2 → Internet Gateway
```

Each private subnet uses a NAT Gateway in the same Availability Zone.

## 8. Public Exposure Rules

Allowed public path:

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
Internal ClusterIP services
```

The following resources must not be directly internet-facing:

* EKS worker nodes.
* Kubernetes Pods.
* Internal Online Boutique services.
* Redis cart service.
* EKS control-plane ENIs.
* Terraform state bucket.
* Any future database or cache.

## 9. Subnet Tagging Standard

All subnets receive common tags:

```text
Project      = online-boutique
Environment  = dev
Owner        = bin
ManagedBy    = Terraform
Component    = network
CostCenter   = learning
```

### Public subnet tags

```text
Tier                         = public
kubernetes.io/role/elb       = 1
kubernetes.io/cluster/<cluster-name> = shared
```

### Private workload subnet tags

```text
Tier                                  = private-workload
kubernetes.io/role/internal-elb       = 1
kubernetes.io/cluster/<cluster-name>  = shared
```

### Private cluster subnet tags

```text
Tier                         = private-cluster
kubernetes.io/cluster/<cluster-name> = shared
```

Reserved data CIDRs are not tagged until their subnets are created.

## 10. VPC-Level Configuration

The VPC must enable:

```text
enable_dns_support   = true
enable_dns_hostnames = true
```

The VPC module must create:

* One VPC.
* One Internet Gateway.
* Two public subnets.
* Two private cluster subnets.
* Two private workload subnets.
* Public and private route tables.
* NAT Gateway resources according to `nat_gateway_mode`.
* Elastic IP addresses for NAT Gateways.
* Standard tags.

The VPC module must not create:

* EKS clusters.
* Node groups.
* Security groups.
* ECR repositories.
* IAM roles.
* Kubernetes resources.
* Application load balancers.
* VPC endpoints.
* VPC Flow Logs.

These belong to later Terraform layers.

## 11. Network Outputs Required by Other Layers

The `env/dev/network` root module must expose:

```text
vpc_id
vpc_cidr
availability_zones
public_subnet_ids
private_cluster_subnet_ids
private_workload_subnet_ids
public_route_table_ids
private_route_table_ids
nat_gateway_ids
internet_gateway_id
```

No secret values may be exposed through Terraform outputs.

## 12. Acceptance Criteria

The network layer is complete when:

* One VPC exists with CIDR `10.20.0.0/16`.
* Six subnets exist across two Availability Zones.
* Public and private subnet CIDRs match this design.
* An Internet Gateway is attached to the VPC.
* Dev has exactly one NAT Gateway.
* Public subnets route default IPv4 traffic to the Internet Gateway.
* Private cluster and workload subnets route default IPv4 traffic through the NAT Gateway.
* No private subnet has a direct route to the Internet Gateway.
* Public subnets have `kubernetes.io/role/elb = 1`.
* Private workload subnets have `kubernetes.io/role/internal-elb = 1`.
* Terraform outputs contain the IDs required by later root modules.
* `terraform fmt`, `terraform validate`, and approved policy checks pass.

## 13. Deferred Network Features

The following are intentionally deferred:

* VPC Flow Logs.
* S3 Gateway Endpoint.
* ECR API and ECR DKR Interface Endpoints.
* CloudWatch Logs Interface Endpoint.
* Network ACL customization.
* IPv6.
* Custom networking for EKS Pods.
* Transit Gateway.
* WAF and CloudFront.

These features require separate architecture decisions before implementation.
