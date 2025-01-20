#!/bin/bash
export KUBECTL="microk8s kubectl"

echo "** Inicializando variables **"
accesschart=$($KUBECTL -n $SDWNS get pods --no-headers -o custom-columns=":metadata.name" | grep accesschart)
cpechart=$($KUBECTL -n $SDWNS get pods --no-headers -o custom-columns=":metadata.name" | grep cpechart)
wanchart=$($KUBECTL -n $SDWNS get pods --no-headers -o custom-columns=":metadata.name" | grep wanchart)
ctrlchart=$($KUBECTL -n $SDWNS get pods --no-headers -o custom-columns=":metadata.name" | grep ctrlchart)

accsdedge1=$(echo "$accesschart" | head -n 1)
cpesdedge1=$(echo "$cpechart" | head -n 1)
wansdedge1=$(echo "$wanchart" | head -n 1)
ctrlsdedge1=$(echo "$ctrlchart" | head -n 1)

echo "Access chart: $accsdedge1"
echo "CPE chart: $cpesdedge1"
echo "WAN chart: $wansdedge1"
echo "CTRL chart: $ctrlsdedge1"

echo "** Killing the process **"
RYU_PID=`$KUBECTL -n $SDWNS exec -i $ctrlsdedge1 -- pgrep -f 'ryu-manager'`
echo "Este es el PID: $RYU_PID"
$KUBECTL -n $SDWNS exec -i $ctrlsdedge1 -- kill $RYU_PID


