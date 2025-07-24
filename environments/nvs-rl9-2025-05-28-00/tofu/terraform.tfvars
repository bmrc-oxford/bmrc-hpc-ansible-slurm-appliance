cluster_name = "rl9-2025-05-28-00"
cluster_domain_suffix = "in.nvs.bmrc.ox.ac.uk"
cluster_networks = [
  {
    network = "analytics-vxlan"
    subnet = "analytics-vxlan"
  }
]
key_pair = "nvs-analytics-2025"
control_node_flavor = "m1.highmem"
login = {
    # Arbitrary group name for these login nodes
    interactive = {
        nodes: ["login-0"]
        flavor: "m1.highmem" # *
    }
}
cluster_image_id = "75c613df-bebb-4aac-9ba4-ffe2654a3421"
compute = {
    # Group name used for compute node partition definition
    general = {
        nodes: ["compute-0", "compute-1"]
        flavor: "m2.large" # *
    }
}

