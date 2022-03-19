#!/bin/sh
cd /opt/kubespray-vagrant
echo "### Install Helm3"
curl --retry 5 --max-time 10 -Lk https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz | tar zxv -C /tmp
mv /tmp/linux-amd64/helm /usr/local/bin/helm && rm -rf /tmp/linux-amd64
chmod +x /usr/local/bin/helm
sleep 5
echo "### Install Prometheus-Grafana Stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
sleep 5
kubectl create ns monitoring
cd kube-prometheus-stack
helm install promgraf  prometheus-community/kube-prometheus-stack -n monitoring  --values values.yml
sleep 5
kubectl --namespace monitoring patch svc promgraf-grafana -p '{"spec": {"type": "LoadBalancer"}}'
echo "### Install MetalLB"
cd ../metallb
kubectl create ns metallb-system
sed -i "s/range/$IPRANGE/" configmap.yml
kubectl apply -f configmap.yml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f metallb.yml

### Check MetalLB Status
metal=0
while [ "$(kubectl get pods -l=component='speaker' -n metallb-system -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ] ||
	[ "$(kubectl get pods -l=component='controller' -n metallb-system -o jsonpath='{.items[*].status.containerStatuses[0].ready}')" != "true" ]; do


   if [ $metal -eq 10 ]; then
	    echo "Please Check MetalLB Pod Status"
	   break
   fi
        metal=$(($metal+1))
sleep 10
echo "Please Wait MetalLB Pod to be ready.."
done

### Check Grafana Status
grafana=0
while [ "$(kubectl get pods -l='app.kubernetes.io/name=grafana' -n monitoring -o jsonpath='{.items[*].status.containerStatuses[1].ready}')" != "true" ] ; do
   
   if [ $grafana -eq 10 ]; then
	    echo "Please Check Grafana Pod Status"
	   break
   fi
        grafana=$(($grafana+1))
sleep 10
echo "Please Wait Grafana Pod to be ready.."
done

echo "### Grafana Access IP"
kubectl get svc promgraf-grafana -n monitoring | awk '{print $4}'
echo "### Grafana User:Pass"
echo "### admin:admin"