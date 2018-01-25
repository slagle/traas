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

If you need your overcloud or overcloud to use a particular
overcloud-full.tar images you can use the
`./scripts/upload-overcloud.sh` utility.

For instance to get pike overcloud images in your account:

    ./scripts/upload-overcloud.sh http://66.187.229.139/builds-pike/current-tripleo/overcloud-full.tar overcloud-pike-full

That’s it.
