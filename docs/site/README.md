# Site-specific Documentation

This document notes changes from the generic docs, and should be read with them.

# Clusters and Environments

This repository defines:
- a `site` environment, used as the basis for all other NVS environments
- TODO: A `production` environment, with cluster name 'nvs' and hostnames "$NODE.in.nvs.bmrc.ox.ac.uk"
- A per-user `dev` environment, with cluster name $USER (for the deploy-host user) and hostnames "$USER-$NODE.in.nvs.bmrc.ox.ac.uk"

The key differences from the default appliance configuration are:
- Use of Manila CephFS shares for/home, and also for /data and /apps shared directories.
- WIP: Use of FreeIPA, with a pre-hook to automatically enrol nodes. This is built into the image.
- TODO: EESSI configuration

Note these clusters operate without outbound internet access, as described in docs/experimental/isolated-clusters.md.

In general, NVS-specific configuration is contained in the `site` environment.

# Prerequisites

The following resources must be manually created before a cluster can be provisioned. This is usually
a one-off action.

## Manila shares
For a `dev` environment use:

```shell
openstack share create --share-type cephfstype --name $USER-home CephFS 2
openstack share create --share-type cephfstype --name $USER-apps CephFS 10
openstack share create --share-type cephfstype --name $USER-data CephFS 16

openstack share access create $USER-home cephx slurm
openstack share access create $USER-apps cephx slurm
openstack share access create $USER-data cephx slurm
```

For the `production` environment use `nvs-` instead of `$USER-` as a prefix and use sizes (in GiB) of 200, 1024 (= 1TiB) and 163840 (= 160 TiB) respectively.

## State volume

For the `production` environment *only*, a state volume must be manually created:

```shell
openstack volume create --size 200 nvs-state
```

For `dev` environments this volume is automatically managed with the cluster.

# Image build

There are 3x image builds used here, referenced by their packer variables file name:

- `base`: This starts from the upstream StackHPC RockyLinux 9 image, and adds the `freeipa` client packages.
  It produces an image `openhpc-freeipa-...`.
- `opengpu`: This starts from the `base` image and adds the `nvidia-open` drivers and `cuda`. It produces an
  image `openhpc-cuda-...`. It is suitable for A100 nodes only. It should support GRES autodetection via the
  `nvidia` (not `nvml`) mechanism.

To build these run the following command in the `packer/` directory:

    PACKER_LOG=1 /usr/local/bin/packer build -on-error=ask -var-file=../environments/site/$NAME.pkrvars.hcl openstack.pkr.hcl

where `$NAME` should be replaced with the variable file name as above, e.g. `base`.

Once the `base` image has built, the `cuda` file should be updated to reference the new image.

To debug failing builds it can be useful to ssh into the build VM. The key file Packer generates will be shown in the connection
string in the logs. Alternatively you can force a specific key using something like:

```yaml
# environments/site/builder.pkrvars.hcl:

# configure to use the same keypair as deployment:
ssh_keypair_name = "nvs-analytics-2025"
ssh_private_key_file = "/home/ff28d9/.ssh/nvs-analytics-2025" # or wherever ...
```


