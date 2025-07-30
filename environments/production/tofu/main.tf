variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

module "cluster" {
  source = "../../site/tofu/"

  cluster_name = "nvs"
  cluster_nodename_template = "$${node}.$${cluster_domain_suffix}"

  login = {
    interactive = {
        nodes = ["login-0"]
        flavor = "m1.highmem"
        fip_addresses = ["10.167.2.160"]
    }
  }

  compute = {
    general = {
      nodes = ["compute-0", "compute-1"]
      flavor = "m2.large"
    }
  }


  additional_nodegroups = {
    squid = { # node for EESSI squid proxy
      nodes = ["eessi-squid-0"]
      flavor = "m1.large" # docs state few cores + few GB of RAM required
      fip_addresses = ["10.167.2.160"]
    }
  }

  state_volume_provisioning = "attach"
  environment_root = var.environment_root
}
