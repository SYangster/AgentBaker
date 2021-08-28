#!/usr/bin/env bash
set -eux

if ! systemctl is-active containerd; then 
  echo "containerd not running"
  exit 1
fi

echo "regenerating payload"
ctr run --mount type=bind,src=/var/lib/cloud,dst=/var/lib/cloud,options=rbind --mount type=bind,src=/opt/azure/containers,dst=/opt/azure/containers,options=rbind --rm {{ GetParameter "bakerRegisry" }}/baker:{{ GetParameter "bakerVersion" }} baker /usr/local/bin/baker "{{ToJSON .}}"
echo "removing semaphores"
rm /var/lib/cloud/instance/sem/config_cc_write_files || true
rm /var/lib/cloud/instance/sem/config_runcmd || true
rm /var/lib/cloud/instance/sem/config_scripts_user || true
echo "rerunning cc_write_files"
base64 -d /var/lib/cloud/instance/user-data.txt > tmp
mv tmp /var/lib/cloud/instance/user-data.txt
mv /var/lib/cloud/instance/scripts/part-001 /tmp/old-001
cloud-init single -n cc_write_files
echo "rerunning runcmd"
cloud-init single -n runcmd
echo "rerunning cc_write_files"
cloud-init single -n scripts_user
echo "executing regenerated CSE file"
bash /opt/azure/containers/cse_regen.sh

