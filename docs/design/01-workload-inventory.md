# Workload Inventory — Online Boutique

## 1. Exposure model

| Component             | Exposure | Notes                                      |
| --------------------- | -------- | ------------------------------------------ |
| frontend              | Public   | Only internet-facing application component |
| cartservice           | Internal | Communicates with Redis                    |
| productcatalogservice | Internal | Product catalogue API                      |
| currencyservice       | Internal | High request-rate service                  |
| checkoutservice       | Internal | Checkout orchestrator                      |
| paymentservice        | Internal | Mock payment processing                    |
| shippingservice       | Internal | Mock shipping estimation                   |
| emailservice          | Internal | Mock email notification                    |
| recommendationservice | Internal | Product recommendations                    |
| adservice             | Internal | Advertising responses                      |
| redis-cart            | Internal | Stateful cart storage                      |
| loadgenerator         | Dev only | Synthetic traffic; disabled by default     |

## 2. Runtime profiles

### Application profile

Enabled in dev, staging, and production:

* frontend
* cartservice
* productcatalogservice
* currencyservice
* checkoutservice
* paymentservice
* shippingservice
* emailservice
* recommendationservice
* adservice
* redis-cart

### Load-test profile

Enabled only when explicitly requested in dev:

* loadgenerator

## 3. Infrastructure implications

* Only frontend requires public ingress.
* All other services remain ClusterIP-only.
* Redis requires separate consideration because it is stateful.
* Worker-node capacity must reserve IP addresses for Pods because EKS VPC CNI allocates Pod IPs from node subnets.
* Currency service and frontend are initial candidates for autoscaling tests.
* Load generator must not run by default because it distorts operational metrics and cost.

## 4. Initial operational assumptions

* Production-like topology uses at least two Availability Zones.
* Production blueprint uses at least two frontend replicas distributed across AZs.
* Dev begins with small node capacity and is destroyed when not in use.
* Application deployment is separate from Terraform infrastructure deployment.
