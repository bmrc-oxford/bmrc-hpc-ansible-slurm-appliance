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

cluster_image_id = "57baae64-b01d-48bc-8066-c9e36354e958"# openhpc-freeipa-250819-1008-472f60c4

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

