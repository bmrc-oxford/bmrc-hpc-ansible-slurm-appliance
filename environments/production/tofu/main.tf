variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

module "cluster" {
  source = "../../site/tofu/"

  cluster_name = "ms"
  cluster_nodename_template = "ms-$${node}.$${cluster_domain_suffix}"

  login = {
    interactive = {
        nodes = ["login-00"]
        flavor = "m1.highmem"
        fip_addresses = ["10.167.2.160"]
    }
  }

  compute = {
    general = {
      nodes = ["general-00", "general-01", "general-02", "general-03",
               "general-04", "general-05", "general-06", "general-07",
               "general-08"]
      flavor = "m3.large"
    }
    general-100disk = {
      nodes = ["general-09", "general-10"]
      flavor = "m3.large.100disk"
    }
    legacy = {
      nodes = ["legacy-00", "legacy-01"]
      flavor = "m3.medium"
    }
    a100 = {
      nodes = ["a100-00", "a100-01", "a100-02", "a100-03"]
      flavor = "a100.4cpu_3gpu_435gb"
    }
    ood = {
      nodes = ["ood-00"]
      flavor = "m3.large.100disk"
    }
  }

  state_volume_provisioning = "attach"
  environment_root = var.environment_root
}
