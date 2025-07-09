# Define site-wide (i.e. all environments) OpenTofu configuration here

cluster_domain_suffix = "in.nvs.bmrc.ox.ac.uk"
cluster_nodename_template = "$${node}.$${cluster_domain_suffix}" # TODO: should change for dev/staging clusters
cluster_networks = [
  {
    network = "analytics-vxlan"
    subnet = "analytics-vxlan"
  }
]

key_pair = "nvs-analytics-2025"
control_node_flavor = "m1.highmem"

cluster_image_id = "0ca4e683-c670-489f-b9b0-ab028d10bbbd" # openhpc-RL9-250704-1445-ff88ca4e, upstream @PR717

login = {
    # Arbitrary group name for these login nodes
    interactive = {
        nodes = ["login-0"]
        flavor = "m1.highmem"
        fip_addresses = ["10.167.2.160"]
    }
}

compute = {
    # Group name used for compute node partition definition
    general = {
        nodes = ["compute-0", "compute-1"]
        flavor = "m2.large" 
    }
}

