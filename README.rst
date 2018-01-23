General information
-------------------

traas is a set of Heat templates and wrapper scripts arond toci_gate_test.sh.
You can think of traas as taking on the role that is done by nodepool and
devstack-gate in CI, but using Heat instead. traas could just be used when you
have access to an OpenStack cloud with Heat that you want to use for TripleO
development.

The Heat templates are used to bring up a multinode environment, and then
trigger some SoftwareDeployment resources on the undercloud node to
execute a tripleo-ci job.

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

Host OpenStack cloud requirements
---------------------------------

traas provisions Nova servers connected to the existing provider networks. A
public provider network is required for external access to undercloud nodes.
Undercloud connections via floating IP are limited with `cluster_ingress_cidr`.
By default, it allows all remote IPs. Make sure to restrict it to the public IP
address of your remote admin/control node, if applicable.

Another two provider private networks define admin and cluster networks for
TripleO deployments. The admin network is only used for SSH access. Floating IP
is associated only to the undercloud port connected to that network. Ingress
rules, DNS setup and routing apply via that admin interface (connected as eth1)
as well. Overcloud nodes have no floating IPs and allow all TCP/UDP traffic
over those private netwroks.

The private cluster network is used with CI multinode scenarios. The ports
connected to that network have Neutron security group/rules disabled. CI
scenarios often creates openvswitch bridges/vxlan tunnels, which fails when
ports security features are enabled.

Note that only the admin network requires an external gateway connection set
up. Both private networks want DHCP enabled and a public DNS server set.
Do not use public resolvers 8.8.8.8 and 8.8.4.4 as those may be rate limiting.

The names of the public and private networks and subnets may be defined as
params, see the ``templates/example-environments/rdo-cloud-env.yaml`` example.
