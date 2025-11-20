image_name = "openhpc-opengpu"
flavor = "m1.medium"                           # 4GB
networks = ["ee42ccc3-907c-405e-8e1e-8ab4322e6bba"]   # analytics-vxlan
source_image_name = "openhpc-freeipa-251120-1343-c2511939" # raw
inventory_groups = "proxy,cuda"            # Additional inventory groups to add build VM to
volume_size = 30
floating_ip = "980eb247-7ccb-4d51-af7e-1bc5cc949ff7" # 10.167.2.61
security_groups = ["default", "SSH"]

