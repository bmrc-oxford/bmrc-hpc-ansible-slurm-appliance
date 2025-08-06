# Site-specific Documentation

This document notes changes from the generic docs, and should be read with them.

# Clusters and Environments

This repository defines:
- A `site` environment, used as the basis for all other NVS environments
- A `production` environment, with cluster name 'nvs' and hostnames "$NODE.in.nvs.bmrc.ox.ac.uk"
- A per-user `dev` environment, with cluster name $USER (for the deploy-host user) and hostnames "$USER-$NODE.in.nvs.bmrc.ox.ac.uk"

The key differences from the default appliance configuration are:
- Use of Manila CephFS shares for/home, and also for /data and /apps shared directories.
- Use of FreeIPA, with a pre-hook to automatically enrol nodes. This is built into the image.
- TODO: Currently EESSI is not available due to the network configuration.

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

# Creating a new checkout

This section describes how to modify the deployed cluster(s) using a new git
checkout.

First clone the repo and change to the `nvs` branch:
```shell
git clone git@github.com:bmrc-oxford/ansible-slurm-appliance.git
cd ansible-slurm-appliance
git checkout nvs
```

Create a file holding the Ansible Vault secret. Usually it is best to do this
outside the repo (so multiple repos can use it and there is no chance of
committing it), e.g. `~/.vault_pass`.

Ensure you have a `clouds.yaml` for the `analytic` project available, either
in the default `~/.config/openstack/` or else set `OS_CLIENT_CONFIG_FILE`.

Now setup the venv and dependencies for the first time:
```
dev/setup-env.sh
```

**IMPORTANT: The above must be re-run when the requirements.{yml,txt} change -
in general it is best to re-run it when changing branches. It is always save to
rerun.**


Now configure your checkout - you need to do this every time you start a shell:

```
export OS_CLOUD=analytics # assuming this is the first key inside `openstack:` in clouds.yaml
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
. venv/bin/activate
. environments/production/activate # or whichever environment
```

**IMPORTANT: Currently the OpenTofu state is NOT remote, hence must be copied
from e.g /home/ff28d9/nvs-slurm-appliance/environments/production/tofu/terraform.tfstate or
wherever the latest change was made.**

# Workflow

In general, the preferred workflow is to use branches to test things on a `dev`
cluster and then merge to `nvs` and deploy to `production` once happy. However
for smaller changes or when the cluster is not in active use you may wish to
use the `nvs` branch and `production` cluster directly.

The full workflow is generally:
- Checkout and pull `nvs` branch to ensure that is up to date

	git checkout nvs
        git pull --prune

- Checkout a new branch

	git checkout feat/foo

- Develop on a `dev` cluster:

	. environments/dev/activate
	vi ...
        # tofu/ansible commands
        git add ...
        git commit -m ...i
        git push

- Create, review and merge a PR to the `nvs` branch.

- In a new terminal, deploy to production:

	. environments/production/activate
        # tofu/ansible commands

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

