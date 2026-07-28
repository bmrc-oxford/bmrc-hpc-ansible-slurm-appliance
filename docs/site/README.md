# BMRC-HPC fork of the ansible-slurm-appliance

This repository is setup to build images and ultimately manage the Slurm cluster
at BMRC.

## Compute node image build

We build a base image from Rocky 9.8, with root on LVM, using disk-image-builder.

See https://github.com/bmrc-oxford/bmrc-openstack-config/pull/9.

The partition scheme is in [etc/openstack-config/openstack-config.yml](https://github.com/bmrc-oxford/bmrc-openstack-config/pull/9/changes#diff-dfb883e7744540de7c00deb54d6d696a1987cb7f558f086abecabcf66ba59bbcR4388).

We then build an appliance image from our base image using `packer build`.
StackHPC repositories are not used: everything is pulled from upstream repos.

See https://github.com/bmrc-oxford/bmrc-hpc-ansible-slurm-appliance/pull/1


Everything is done on the `cloudadmin001` machine, that has all the required tools installed already.

### DIB instructions:

Build must be done by a user allowed to do arbitrary sudo commands (to mount the filesystem on a loop device, etc.).

Follow the [Preparation section](https://github.com/bmrc-oxford/bmrc-openstack-config#preparation) in the Readme.

**One-time setup**

	# git clone git@github.com:bmrc-oxford/bmrc-openstack-config.git
	# cd bmrc-openstack-config
	# git checkout ft/image-rocky_linux_9_8_lvm
	# python3 -m venv openstack-venv
	# source openstack-venv/bin/activate
	# python -m pip install --upgrade pip
	# pip install -r requirements.txt
	# ansible-galaxy collection install -p ansible/collections -r requirements.yml

Edit `etc/openstack-config/openstack-config.yml`

- `bmrc_image_rocky_9_8_lvm` contains configuration, like extra packages to add. At this step we should keep
  a very minimal set of packages: we should install them using the ansible-slurm-appliance playbooks later.

- `bmrc_dib_block_device_config_uefi_lvm` contains the partition layout (EFI + padding partition + LVM PV),
   and the LVM configuration (the `vgroot` volume group, containing logical volumes for `/`, `/tmp`, etc.).
   The PV and appropriate LVs shall be resized during/after packer build.

- you should comment-out the other images in the `openstack_images` list, to only build `bmrc_image_rocky_9_8_lvm`.

Playbooks try to update python, pip, etc. and to recreate the `ansible/openstack-config-venv` each time, which is useless.
Here is a longer invocation that ensures it doesn't.

**Image build**

Source the openstack credentials:

	# source /home/stack/dawud/2024.1/src/kayobe-config/etc/kolla/public-openrc.sh

Build the image:

    # ./tools/openstack-config -p ansible/openstack-images.yml -- -e os_openstacksdk_install_package_dependencies=false -e os_openstackclient_install_package_dependencies=false -e os_virtualenv_python=/usr/bin/python3.9 -D

Build logs (and errors) are in `ansible/openstack-config-image-cache/rocky_linux_9_8_lvm/rocky_linux_9_8_lvm.stdout`.

The built image is in `ansible/openstack-config-image-cache/rocky_linux_9_8_lvm`. Ensure you clean it up manually if you want to rebuild it.

The uploaded image is used as source for the packer build.

### Packer build instructions

See https://github.com/bmrc-oxford/bmrc-hpc-ansible-slurm-appliance/pull/1

Packer talks to openstack to spawn a VM from our base image, then runs the `ansible/fatimage.yml` playbook
to configure it and finally tears down the VM and tasks openstack to convert the resulting disk to an image.

Packer build is also done on the `cloudadmin001` node, but as your regular user.

Ensure you have openstack credentials. The `./dev/activate-bmrc-staging` script will remind you to set it up.

**One time setup**

	# git clone git@github.com:bmrc-oxford/bmrc-hpc-ansible-slurm-appliance.git
	# git checkout ft/add_bmrc-staging-env
	# ./dev/setup-env.sh

**Build**
	# ./dev/activate-bmrc-staging
	# cd packer
	# PACKER_LOG=1 packer build --on-error=ask -var-file=$PKR_VAR_environment_root/bmrc.pkrvars.hcl openstack.pkr.hcl 2>&1 | tee packer-build.log
	# ../dev/image-set-properties.sh $IMAGE_NAME_OR_ID

This builds the image, then sets properties for it to be used.

The variable file `environments/bmrc-staging/bmrc.pkrvars.hcl` contains settings for the `demo` project.
Networks and floating IP are to be changed for `legacy_project`.

### Deployment

Deployment has not been considered yet.
