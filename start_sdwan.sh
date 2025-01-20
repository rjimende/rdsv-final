#!/bin/bash

# Requires the following variables
# KUBECTL: kubectl command
# SDWNS: cluster namespace in the cluster vim
# NETNUM: used to select external networks
# VCPE: "pod_id" or "deploy/deployment_id" of the cpd vnf
# VWAN: "pod_id" or "deploy/deployment_id" of the wan vnf
# REMOTESITE: the "public" IP of the remote site

set -u # to verify variables are defined
: $KUBECTL
: $SDWNS
: $NETNUM
: $VACC
: $VCPE
: $VWAN
: $VCTL
: $REMOTESITE


if [[ ! $VACC =~ "-accesschart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <access_deployment_id>: $VACC"
    exit 1
fi

if [[ ! $VCPE =~ "-cpechart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <cpe_deployment_id>: $VCPE"
    exit 1
fi

if [[ ! $VWAN =~ "-wanchart"  ]]; then
   echo ""       
   echo "ERROR: incorrect <wan_deployment_id>: $VWAN"
   exit 1
fi

if [[ ! $VCTL =~ "-ctrlchart"  ]]; then
   echo ""       
   echo "ERROR: incorrect <wan_deployment_id>: $VCTL"
   exit 1
fi

ACC_EXEC="$KUBECTL exec -n $SDWNS $VACC --"
CPE_EXEC="$KUBECTL exec -n $SDWNS $VCPE --"
WAN_EXEC="$KUBECTL exec -n $SDWNS $VWAN --"
CTL_EXEC="$KUBECTL exec -n $SDWNS $VCTL --"
CTL_SERV="${VCTL/deploy\//}"
# Router por defecto inicial en k8s (calico)
K8SGW="169.254.1.1"

## 1. Obtener IPs y puertos de las VNFs
echo "## 1. Obtener IPs y puertos de las VNFs"

IPACCESS=`$ACC_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS = $IPACCESS"

IPCPE=`$CPE_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE = $IPCPE"

IPWAN=`$WAN_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN = $IPWAN"

IPCTL=`$CTL_EXEC hostname -I | awk '{print $1}'`
echo "IPCTL = $IPCTL"

PORTCTL=`$KUBECTL get -n $SDWNS -o jsonpath="{.spec.ports[0].nodePort}" service $CTL_SERV`
echo "PORTCTL = $PORTCTL"

## 2. En VNF:cpe agregar un bridge y sus vxlan
echo "## 2. En VNF:cpe agregar un bridge y configurar IPs y rutas"

$CPE_EXEC ip route add $IPWAN/32 via $K8SGW
$CPE_EXEC ovs-vsctl add-br brwan
$CPE_EXEC ip link add cpewan type vxlan id 5 remote $IPWAN dstport 8741 dev eth0
$CPE_EXEC ovs-vsctl add-port brwan cpewan
$CPE_EXEC ifconfig cpewan up
$CPE_EXEC ip link add sr1sr2 type vxlan id 12 remote $REMOTESITE dstport 8742 dev net$NETNUM
$CPE_EXEC ovs-vsctl add-port brwan sr1sr2
$CPE_EXEC ifconfig sr1sr2 up

