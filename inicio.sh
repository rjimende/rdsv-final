#!/bin/bash

cd ~/shared/rdsv-final/bin
./prepare-k8slab   # creates namespace and network resources

source ~/.bashrc

echo $SDWNS
# debe mostrar el valor
# 'rdsv'

sleep 2

sudo ovs-vsctl show

kubectl get -n $SDWNS network-attachment-definitions

cd ~/shared/rdsv-final/vnx
sudo vnx -f sdedge_nfv.xml -t
