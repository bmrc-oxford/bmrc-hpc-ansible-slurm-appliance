# Site-specific Documentation

This document notes changes from the generic docs, and should be read with them.

# Clusters and Environments

This repository defines:
- A `site` environment, used as the basis for all other NVS environments
- A `production` environment, with cluster name 'nvs' and hostnames "$NODE.in.nvs.bmrc.ox.ac.uk"
- A per-user `dev` environment, with cluster name $USER (for the deploy-host user)
  and hostnames "$USER-$NODE.in.nvs.bmrc.ox.ac.uk"

In general, NVS-specific configuration is contained in the `site` environment.
Key differences from the default appliance configuration:
- Manila CephFS shares for `/home`, `/data` and `/apps` shared directories -
  the `/apps` one is shared between all environments.
- Use of the NVS FreeIPA server. A pre-hook and encrypted admin creds are used
  to ensure the hosts exist in IPA but otherwise clusters use the default
  approach of enrolling hosts via OTP and re-enrolling them using persisted
  keytabs.
- Currently EESSI is not available due to the network configuration although
  there is a draft [upstream PR](https://github.com/stackhpc/ansible-slurm-appliance/pull/753)
  to enable this.

# Access

For SSH, VPN access is required. Currently the dev cluster does not have port 22
allowed through the firewall so access must be from a host inside the firewall.

For Open Ondemand, sshuttle in using dns, e.g. using the nvs-admin host:

```shell
sshuttle --dns -r USER@10.161.0.2 10.56.0.0/22 10.167.2.163 10.167.2.160
```

where the final addresses are the login FIPs for the dev `ff28d9` and
production cluster respectively.

Login nodes and Open Ondemand can then be accessed at:
- Production: [ms-login-00.nvs.bmrc.ox.ac.uk](https://ms-login-00.nvs.bmrc.ox.ac.uk)
- Dev: [ff28d9-login-00.nvs.bmrc.ox.ac.uk](https://ff28d9-login-00.nvs.bmrc.ox.ac.uk)

Note these DNS names are the login nodes' FQHN without the `.in` portion.

# Networking
All environments operate without outbound internet access, as described in
[docs/experimental/isolated-clusters.md](docs/experimental/isolated-clusters.md).

Outside of the appliance scope there is:
- A firewall, configured to allow inbound HTTPS/SSH to cluster FIPs.
- A squid proxy. This has basic auth and allows access only from specific IPs.
  It only allows access to whitelisted URLs.

To allow package installation during image build, the build VM attaches a
specific FIP already allocated in the OpenStack project. There is appropriate
firewall/proxy configuration to allow this to reach Ark and other upstream
sources. On the appliance side:
  - The build FIP is defined in `nvs-slurm-appliance/environments/site/*.pkrvars.hcl`
  - The configuration to allow the build VM access to the proxy is in
    `environments/site/inventory/group_vars/builder/` and is currently the
    configuration for the user `ff289d9`.

Note that the NVS FreeIPA server is automatically configured as the OpenStack
nameserver so no appliance configuration for this is required. Hosts have DNS
records from this nameserver but the `etc_hosts` role is still used (probably
unnecessarily). For the login/ondemand nodes, the FIPs are given a DNS record
for the FQHN without the `.in` portion (this was manual FreeIPA configuration
outside the appliance).

# Prerequisites

The following resources must be manually created before a cluster can be
provisioned. This is usually a one-off action, i.e. will only be required for
new environments.

## Manila shares
Each environment mounts shares `home`, `apps and `data`. All clusters mount the
same `home` and `apps` shares, whereas the `data` share is environment-specific.
Example of `data` share creation for the `dev` environment:

```shell
openstack share create --share-type cephfstype --name $USER-data CephFS 16
openstack share access create $USER-data cephx slurm
```

For the home and apps shares and the `production` environment's `data` share use
the prefix `ms-` instead of `$USER-`. These shares have sizes (in GB) as follows:
- `ms-home`: 200
- `ms-apps`: 1024
- `ms-data`: 163840

## State volume

For the `production` environment *only*, a state volume must be manually created:

```shell
openstack volume create --size 200 nvs-state
```

For `dev` environments this volume is automatically managed with the cluster.

## Floating IP

For the `production` environment *only* a floating IP should be allocated to
the project using:

```shell
openstack floating ip create --description 'Slurm production cluster login node' external
```

and the resulting IP should be set in `nvs-slurm-appliance/environments/production/tofu/main.tf`
as `cluster.login.interactive.fip_addresses = [<FIP>]`.

For `dev` environments the FIP is automatically managed with the cluster.

## External networking config

- Inbound HTTPS and SSH access must be allowed to the login FIP.
- The build VM FIP must be allowed to access the squid proxy.
- User credentials must be created for the squid proxy.

# Creating a new checkout

This section describes how to modify the deployed cluster(s) using a new git
checkout.

First clone the repo and change to the `nvs` branch:
```shell
git clone git@github.com:bmrc-oxford/ansible-slurm-appliance.git
cd ansible-slurm-appliance
git checkout nvs
```

Create a script showing the Ansible Vault secret:

```shell
# ~/.vault_pass:
#!/usr/bin/bash
echo $VAULT_PASSWORD
```
and make it executable.

Ensure you have a `clouds.yaml` for the `analytic` project available, either
in the default `~/.config/openstack/` or else set `OS_CLIENT_CONFIG_FILE`.

Now setup the venv and dependencies for the first time:

```shell
dev/setup-env.sh
```

**IMPORTANT: The above must be re-run when the requirements.{yml,txt} change -
in general it is best to re-run it when changing branches. It is always safe to
rerun.**

Now configure your checkout - you need to do this every time you start a shell:

```
export OS_CLOUD=analytics # assuming this is the first key inside `openstack:` in clouds.yaml
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
  export VAULT_PASSWORD=<secret>
. venv/bin/activate
. environments/production/activate # or whichever environment
```

**IMPORTANT: Currently the OpenTofu state is NOT remote, hence must be copied
from e.g /home/ff28d9/nvs-slurm-appliance/environments/production/tofu/terraform.tfstate or
wherever the latest change was made.**

# Workflow

In general, the preferred workflow is to:
1. Create a branch and use to develop/test on a `dev` cluster.
2. Ensure branch is up to date and get PR approved.
3. Deploy to `production` then merge branch to `nvs`.

Detailed steps:

- Checkout and pull `nvs` branch to ensure that is up to date

  ```shell
  git checkout nvs
  git pull --prune
  ```

- Checkout a new branch

  ```shell
  git checkout -b feat/foo
  ```

- Develop on a `dev` cluster:

  ```shell
  . environments/dev/activate
  # modify files, run tofu/ansible commands
  git add ...
  git commit -m ...i
  git push
  ```

- Create and review PR to the `nvs` branch.

- In a new terminal, deploy to production:

  ```shell
  . environments/production/activate
  # tofu/ansible commands
  ```

- Commit any changes to the production hosts file (due to tofu changes)

- Merge PR.

# Image build

There are 2x image builds , referenced by their Packer variables file name in
`environments/site/*.pkrvars.hcl`:

- `base`: This starts from the upstream StackHPC RockyLinux 9 image, and:
  - Installs `freeipa` client packages.
  - Installs `ondemand-dex` package for OIDC login to Open Ondemand via LDAP.
  - Installs a few additional packages specified in
    `environments/site/inventory/group_vars/all/defaults.yml:appliances_extra_packages_other`
  
  This produces an image `openhpc-freeipa-...`.

- `opengpu`: This starts from the `base` image and adds the `nvidia-open`
  drivers and `cuda`. It produces an image `openhpc-cuda-...` suitable for A100
  nodes only. It should support GRES autodetection via the `nvidia` (not `nvml`)
  mechanism.

To build these run the following command in the `packer/` directory:

    PACKER_LOG=1 /usr/local/bin/packer build -on-error=ask -var-file=../environments/site/$NAME.pkrvars.hcl openstack.pkr.hcl

where `$NAME` should be replaced with the variable file name as above, e.g. `base`.

Once the `base` image has built, the `opengpu` Packer variables file must be
updated to reference the new `base` image.

After each build, the properties should be set using:

```shell
dev/image-set-properties.sh <image_name_or_id>
```

To debug failing builds it can be useful to ssh into the build VM. The key file
Packer generates will be shown in the connection string in the logs.
Alternatively you can force a specific key using something like:

```yaml
# environments/site/builder.pkrvars.hcl:
# configure to use the same keypair as deployment:
ssh_keypair_name = "nvs-analytics-2025"
ssh_private_key_file = "/home/ff28d9/.ssh/nvs-analytics-2025" # or wherever ...
```

# Testing

The cluster test user `xy4ph1` can be used for testing ssh/OnDemand etc. This
is in the group `analytusers` which via HBAC allows access to `analyt_hosts`,
which includes the cluster's login nodes.
