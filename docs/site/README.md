# Site-specific Documentation

This document notes changes from the generic docs, and should be read with them.


# Image build


Use this packer command (NB in the `packer/` directory):

    PACKER_LOG=1 /usr/local/bin/packer build -on-error=ask -var-file=../environments/site/builder.pkrvars.hcl openstack.pkr.hcl



#TODO: list things which should commonly be specified here.

