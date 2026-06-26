# Project Charter — Online Boutique AWS Platform

## 1. Objective

Build a production-style AWS platform for Google Online Boutique using Terraform.

The platform must demonstrate:

* Reusable Terraform modules.
* Remote, encrypted, versioned, locked Terraform state.
* Environment separation: dev, staging, production.
* AWS EKS with private worker nodes.
* Public application exposure through AWS Application Load Balancer.
* GitHub Actions authentication through AWS OIDC federation.
* Infrastructure changes reviewed through pull requests.
* Policy-as-code checks before infrastructure deployment.
* Basic logging, tagging, cost control, and operational runbooks.

## 2. System boundary

This repository manages cloud infrastructure only:

* AWS networking.
* IAM and GitHub OIDC roles.
* EKS cluster and worker capacity.
* ECR repositories.
* Security foundations.
* Observability foundations.
* Terraform backend and policies.

This repository does not manage application source code.

Application manifests, Helm charts, Argo CD configuration, and deployment promotion belong to a separate GitOps repository.

## 3. Environment strategy

| Environment | Purpose                                                  | Deployment model                             |
| ----------- | -------------------------------------------------------- | -------------------------------------------- |
| dev         | Real deployment and functional validation                | Running when actively used                   |
| staging     | Integration and release validation                       | On-demand or scheduled                       |
| production  | Production-ready blueprint and protected deployment path | Not permanently running during project phase |

## 4. In scope — Version 1

* One AWS account.
* Region: ap-southeast-2.
* One VPC per environment.
* Two Availability Zones.
* Public subnets for internet-facing ALB and NAT Gateway.
* Private subnets for EKS worker nodes and application Pods.
* Amazon EKS.
* Managed node group.
* Amazon ECR.
* AWS Load Balancer Controller.
* S3 Terraform state backend with KMS encryption, versioning, and S3 lockfile.
* GitHub Actions OIDC role.
* CloudWatch control plane logging.
* Terraform policy checks for tags, encryption, S3 public access, and security group exposure.

## 5. Out of scope — Version 1

* Multi-account landing zone.
* Multi-region disaster recovery.
* AWS WAF and CloudFront.
* RDS, ElastiCache, and persistent production databases.
* Service mesh.
* Full SIEM/SOC stack.
* Full self-hosted CI runner inside the VPC.
* Karpenter advanced capacity management.

## 6. Success criteria

The project is complete when:

* Infrastructure can be deployed from a clean AWS account using Terraform.
* Every root Terraform layer uses an independent remote state.
* EKS worker nodes have no public IP address.
* Only the application ALB accepts inbound public web traffic.
* GitHub Actions uses temporary OIDC credentials, not static AWS keys.
* A pull request produces Terraform validation, plan, security scan, and policy results.
* The Online Boutique frontend is reachable through an ALB endpoint.
* A destroy procedure and state recovery runbook exist.
