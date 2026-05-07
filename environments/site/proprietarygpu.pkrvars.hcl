# BUILD THIS FIRST to make adding other packages easier!
image_name = "openhpc-proprietarygpu"
flavor = "m1.medium"                           # 4GB
networks = ["ee42ccc3-907c-405e-8e1e-8ab4322e6bba"]   # analytics-vxlan
source_image_name = "openhpc-RL9-251119-1202-332ac921.raw"   # Upstream image
inventory_groups = "proxy,cuda,proprietarygpu"
volume_size = 30
floating_ip = "980eb247-7ccb-4d51-af7e-1bc5cc949ff7" # 10.167.2.61
security_groups = ["default", "SSH"]

