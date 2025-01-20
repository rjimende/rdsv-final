export SIID="$NSID1" # $NSID1, for OSM, to be defined in calling shell
export NETNUM=1 # used to select external networks
export REMOTESITE="10.100.2.1"
export KUBECTL="microk8s kubectl"
export VACC="deploy/access$NETNUM-accesschart"
export VCPE="deploy/cpe$NETNUM-cpechart"
export VWAN="deploy/wan$NETNUM-wanchart"
export VCTL="deploy/ctrl$NETNUM-ctrlchart"
# CUSTUNIP: the ip address for the home side of the tunnel
export CUSTUNIP="10.255.0.2"
# CUSTPREFIX: the customer private prefix
export CUSTPREFIX="10.20.1.0/24"
# VNFTUNIP: the ip address for the vnf side of the tunnel
export VNFTUNIP="10.255.0.1"
# VCPEPUBIP: the public ip address for the vcpe
export VCPEPUBIP="10.100.1.1"
# VCPEGW: the default gateway for the vcpe
export VCPEGW="10.100.1.254"


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
: $CUSTUNIP
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW


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
   echo "ERROR: incorrect <ctrl_deployment_id>: $VCTL"
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

## 2. En VNF:ctl arrancar controlador SDN"
echo "## 2. En VNF:ctl arrancar controlador SDN"
$CTL_EXEC /usr/local/bin/ryu-manager flowmanager/flowmanager.py ryu.app.ofctl_rest 2>&1 | tee ryu.log &
$CTL_EXEC ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py &

## 3. En VNF:wan activar el modo SDN del conmutador
echo "## 3. En VNF:wan activar el modo SDN del conmutador"

$WAN_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$WAN_EXEC ovs-vsctl set-fail-mode brwan secure
$WAN_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000001
$WAN_EXEC ovs-vsctl set-controller brwan tcp:$IPCTL:6633
$WAN_EXEC ovs-vsctl set-manager ptcp:6632

## 4. En VNF:cpe activar el modo SDN del conmutador
echo "## 4. En VNF:cpe activar el modo SDN del conmutador"

$CPE_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$CPE_EXEC ovs-vsctl set-fail-mode brwan secure
$CPE_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000002
$CPE_EXEC ovs-vsctl set-controller brwan tcp:$IPCTL:6633
$CPE_EXEC ovs-vsctl set-manager ptcp:6632

## 5. En VNF:access activar el modo SDN del conmutador
echo "## 5. En VNF:access activar el modo SDN del conmutador"

$ACC_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$ACC_EXEC ovs-vsctl set-fail-mode brwan secure
$ACC_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000003
$ACC_EXEC ovs-vsctl set-controller brwan tcp:$IPCTL:6633
$ACC_EXEC ovs-vsctl set-manager ptcp:6632


TCP="tcp:$IPWAN:6632"

## 6. Aplica las reglas
echo "## 6. Aplica las reglas"                   
$CTL_EXEC curl -X PUT -d "$TCP" http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr
$CTL_EXEC curl -X POST -d '{"port_name": "axswan", "type": "linux-htb", "max_rate": "10000000", "queues": [{"min_rate": "800000"}]}' http://localhost:8080/qos/queue/0000000000000001
$CTL_EXEC curl -X POST -d '{"match": {"nw_dst": "10.20.1.2", "nw_proto": "UDP", "udp_dst": "5005"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001
$CTL_EXEC  curl -X GET http://localhost:8080/qos/rules/0000000000000001

#echo "--"
#echo "sdedge$NETNUM: abrir navegador para ver sus flujos Openflow:"
#echo "firefox http://localhost:$PORTCTL/home/ &"