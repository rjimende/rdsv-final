cd ~/shared/rdsv-final/bin
./prepare-k8slab   # creates namespace and network resources

source ~/.bashrc

echo $SDWNS
# debe mostrar el valor
# 'rdsv'

sleep 2

sudo ovs-vsctl show

if [ -z "$SDWNS" ]; then
    echo "La variable global \$SDWNS no está definida. Es necesario configurar el entorno de OSM previamente."
    exit 1
fi

#helm
mkdir $HOME/helm-files
cd ~/helm-files
helm package ~/shared/rdsv-final/helm/accesschart
helm package ~/shared/rdsv-final/helm/cpechart
helm package ~/shared/rdsv-final/helm/wanchart
helm package ~/shared/rdsv-final/helm/ctrlchart
helm repo index --url http://127.0.0.1/ .
cat index.yaml
docker run --restart always --name helm-repo -p 8080:80 -v ~/helm-files:/usr/share/nginx/html:ro -d nginx

kubectl get -n $SDWNS network-attachment-definitions
cd $HOME/shared/rdsv-final/vnx
sudo vnx -f sdedge_nfv.xml -t