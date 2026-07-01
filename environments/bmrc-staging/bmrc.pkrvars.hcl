image_name = "openhpc-bmrc"
flavor = "m1.medium"                           # 4GB
networks = ["52381e53-f9c4-4c84-ad75-1bd5e70f2855"] # demo-vxlan
source_image_name = "rocky_linux_9_8_lvm"
inventory_groups = "fatimage,freeipa_client,openondemand,extra_packages,lustre"
volume_size = 50
security_groups = ["default", "SSH-demo"]
ssh_username = "cloud-user"
