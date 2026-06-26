availability_zones = {
  az1 = {
    name                  = "ap-southeast-2a"
    public_cidr           = "10.20.0.0/24"
    private_cluster_cidr  = "10.20.2.0/24"
    private_workload_cidr = "10.20.16.0/20"
  }

  az2 = {
    name                  = "ap-southeast-2b"
    public_cidr           = "10.20.1.0/24"
    private_cluster_cidr  = "10.20.3.0/24"
    private_workload_cidr = "10.20.32.0/20"
  }
}