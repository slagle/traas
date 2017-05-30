traas is a set of Heat templates and wrapper scripts arond toci_gate_test.sh.
You can think of traas as taking on the role that is done by nodepool and
devstack-gate in CI, but using Heat instead. traas could just be used when you
have access to an OpenStack cloud with Heat that you want to use for TripleO
development.

The Heat templates are used to bring up a multinode environment, and then
trigger some SoftwareDeployment resources on the undercloud node to
execute a tripleo-ci job.

Here are example commands to use it::

  $ mkvirtualenv ocata
  $ wget https://raw.githubusercontent.com/openstack/requirements/stable/ocata/upper-constraints.txt -O /tmp/ocata
  $ pip install -c /tmp/ocata python-openstackclient python-heatclient
  $ git clone https://github.com/slagle/traas.git
  $ openstack --os-cloud rdo-cloud stack create foo \
  -t traas/templates/traas.yaml \
  -e traas/templates/traas-resource-registry.yaml \
  -e traas/templates/example-environments/rdo-cloud-env.yaml \
  --wait

The main template is::

	 templates/traas.yaml

You can see the resources there for an undercloud node and set of overcloud
nodes, etc. The templates requires some parameters. Included, there are some
sample environment files that can be used to set the required parameters at::

  templates/example-environments

Once the nodes are up, the main script that is triggered is::

	scripts/traas.sh

The script logs to `tripleo-root/traas.log` in the home directory of the
`centos` user. This logfile is equivalent to the upstream `console.html` output
from a ci job.

That is a simple wrapper around toci_gate_test.sh. The $TOCI_JOBTYPE variable
(passed in via a Heat parameter) is what drives which job is executed. Since it
just executes toci_gate_test.sh, what tool tripleo-ci uses for that jobtype is
what tool gets used to execute the job (tripleo-quickstart, tripleo.sh, etc).

By default, it will be set to `multinode-1ctlr-featureset004` which is the
default nonha multinode job used upstream in tripleo-ci.

It executes the ci job end to end and then leaves the environment up at the end
for inspection and/or development.

You may as well pre-create a volume and save docker images for future use.
Define the ``volume_id`` to ensure the pre-created volume is mounted for
an undercloud node. Then, from that undercloud node containing docker images
(see the `overcloud-prep-containers` quickstart-extras role for details),
do a one time export steps, for example::

  # mkfs.ext4 -F /dev/vdb
  # echo "/dev/vdb /mnt/docker_images ext4 defaults 0 0" >> /etc/fstab
  # mkdir -p /mnt/docker_images
  # mount -a
  # docker save $(docker images -f dangling=false | \
  awk '/^docker\.io/ {print $1}' | sort -u) | gzip -6 \
  > /mnt/docker_images/tripleoupstream.tar
  # sync
  # umount /mnt/docker_images

From now on, consequent stacks will load the saved images from the given
``volume_id`` while running the undercloud cloud-init user script.

.. note:: Changing docker graph driver or remapping its userns will reset
  loaded docker images.

For overcloud nodes to access loaded images from a local registry, configure
the registry for the undercloud node, like this::

  # docker pull registry
  # docker run -dit -p 8787:5000 --name registry registry
  # curl -s <ctl_plane_ip>:8787/v2/_catalog | python -mjson.tool

There the `ctl_plane_ip` comes from the wanted quickstart-extras variables.
