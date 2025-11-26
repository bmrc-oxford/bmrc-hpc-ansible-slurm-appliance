variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

data "openstack_images_image_v2" "opengpu" {
    # Image for A100 (nvidia-open drivers) - just allows referencing by name
    name = "openhpc-opengpu-251126-1419-eff83e31" # (v2.8.1)
}

locals {
 user_name = basename(pathexpand("~"))
}

# Cannot use a pre-allocated FIP for dev environment as there may be multiple instantiations
resource "openstack_networking_floatingip_v2" "login" {
  pool = "external"
  description = "Slurm ${local.user_name} cluster login node"
}

module "cluster" {
  source = "../../site/tofu/"

  cluster_name = local.user_name
  cluster_nodename_template = "${local.user_name}-$${node}.$${cluster_domain_suffix}"

  login = {
    interactive = {
        nodes = ["login-00"]
        flavor = "m1.highmem"
        fip_addresses = [openstack_networking_floatingip_v2.login.address]
    }
  }

  compute = {
    general = {
      nodes = ["compute-00", "compute-01"]
      flavor = "m2.large"
    }
  a100 = {
      nodes = ["a100-00"]
      flavor = "a100.4cpu_3gpu_435gb"
      image_id = data.openstack_images_image_v2.opengpu.id
    }
  }

  environment_root = var.environment_root
}
