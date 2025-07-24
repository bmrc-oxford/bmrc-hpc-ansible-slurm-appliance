variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

locals {
 user_name = basename(pathexpand("~"))
}
module "cluster" {
  source = "../../site/tofu/"

  cluster_name = local.user_name
  cluster_nodename_template = "${local.user_name}-$${node}.$${cluster_domain_suffix}"

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

  environment_root = var.environment_root
}
