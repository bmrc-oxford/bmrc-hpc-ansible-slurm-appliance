variable "environment_root" {
    type = string
    description = "Path to environment root, automatically set by activate script"
}

data "openstack_images_image_v2" "opengpu" {
  # Image for A100 (nvidia-open drivers) - just allows referencing by name
  name = "openhpc-opengpu-250818-1049-472f60c4"
}

module "cluster" {
  source = "../../site/tofu/"

  cluster_name = "ms"
  cluster_nodename_template = "ms-$${node}.$${cluster_domain_suffix}"

  cluster_image_id = "57baae64-b01d-48bc-8066-c9e36354e958"# openhpc-freeipa-250819-1008-472f60c4

  login = {
    interactive = {
        # NB: login nodes use image with ondemand-dex package
        # Only deployed to these nodes to minimise cluster disruption
        # but could be used for all nodes at a future upgrade
        image_id = "c3ae586b-48c5-4f92-8c84-9187ebdf63cc" # openhpc-freeipa-251030-1621-727d972
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
    legacy = {
      nodes = ["legacy-00", "legacy-01"]
      flavor = "m3.medium"
    }
    a100 = {
      nodes = ["a100-00", "a100-01", "a100-02", "a100-03"]
      flavor = "a100.4cpu_3gpu_435gb"
      image_id = data.openstack_images_image_v2.opengpu.id
    }
  }

  state_volume_provisioning = "attach"
  environment_root = var.environment_root
}
