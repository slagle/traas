#!/bin/bash

# This script will setup parallel configurations of
# os-collect-config/os-refresh-config/os-apply-config
# so that the instance can poll for configuration from the host cloud without
# interfering with how these tools are used during the undercloud installation.

set -eux

sudo mkdir -p /etc/host-cloud
sudo mkdir -p /var/lib/host-cloud
sudo mkdir -p /usr/libexec/host-cloud
sudo mkdir -p /usr/libexec/host-cloud/os-apply-config/templates/etc/host-cloud
sudo mkdir -p /usr/libexec/host-cloud/os-apply-config/templates/var/run/host-cloud
sudo mkdir -p /var/run/host-cloud

sudo cp -r /usr/libexec/os-refresh-config /usr/libexec/host-cloud || :
sudo cp -r /usr/libexec/os-apply-config/templates/etc/* /usr/libexec/host-cloud/os-apply-config/templates/etc/host-cloud || :
sudo cp -r /usr/libexec/os-apply-config/templates/var/run/* /usr/libexec/host-cloud/os-apply-config/templates/var/run/host-cloud || :
sudo cp /etc/os-collect-config.conf /etc/host-cloud/os-collect-config.conf

sudo sed -i "s#command = os-refresh-config#command = /usr/local/bin/host-cloud-os-refresh-config#" /usr/libexec/host-cloud/os-apply-config/templates/etc/host-cloud/os-collect-config.conf
sudo sed -i "s#command = os-refresh-config#command = /usr/local/bin/host-cloud-os-refresh-config#" /etc/host-cloud/os-collect-config.conf

sudo cp /lib/systemd/system/os-collect-config.service /lib/systemd/system/host-cloud-os-collect-config.service
sudo sed -i "s#ExecStart=.*#ExecStart=/usr/bin/os-collect-config --config-file /etc/host-cloud/os-collect-config.conf --cachedir /var/lib/host-cloud/os-collect-config#" /lib/systemd/system/host-cloud-os-collect-config.service
sudo systemctl daemon-reload
sudo systemctl enable host-cloud-os-collect-config
sudo systemctl stop os-collect-config
sudo systemctl disable os-collect-config

cat >host-cloud-os-refresh-config<<EOF
#!/bin/bash
set -eux

export OS_REFRESH_CONFIG_BASE_DIR=/usr/libexec/host-cloud/os-refresh-config
export OS_CONFIG_FILES_PATH=/var/lib/host-cloud/os-collect-config/os_config_files.json
export OS_CONFIG_APPLIER_TEMPLATES=/usr/libexec/host-cloud/os-apply-config/templates
export HEAT_CONFIG_DEPLOYED=/var/lib/host-cloud/heat-config/deployed
export HEAT_SHELL_CONFIG=/var/run/host-cloud/heat-config/heat-config

sudo mkdir -p /var/run/host-cloud
/bin/os-refresh-config --lockfile /var/run/host-cloud/os-refresh-config.lock
EOF

sudo cp host-cloud-os-refresh-config /usr/local/bin/host-cloud-os-refresh-config
sudo chmod +x /usr/local/bin/host-cloud-os-refresh-config
