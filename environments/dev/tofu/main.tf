variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

locals {
 user_name = basename(pathexpand("~"))
}

# Cannot use a pre-allocated FIP for dev environment as there may be multiple instantiations
resource "openstack_networking_floatingip_v2" "login" {
  pool = "external"
}

module "cluster" {
  source = "../../site/tofu/"

  cluster_name = local.user_name
  cluster_nodename_template = "${local.user_name}-$${node}.$${cluster_domain_suffix}"

  login = {
    interactive = {
	image_id = "c3ae586b-48c5-4f92-8c84-9187ebdf63cc" # openhpc-freeipa-251030-1621-727d9722 - with ondemand-dex
        nodes = ["login-00"]
        flavor = "m1.highmem"
        fip_addresses = [openstack_networking_floatingip_v2.login.address]
    }
  }

  compute = {
    general = {
      nodes = ["compute-00"]
      flavor = "m2.large"
    }
  }

  environment_root = var.environment_root
}
