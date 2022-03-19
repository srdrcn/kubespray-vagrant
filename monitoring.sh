#!/bin/sh

git clone https://github.com/srdrcn/kubespray-vagrant /opt/kubespray-vagrant
cd opt/kubespray-vagrant
echo "### Install Helm3"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
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
echo "###Grafana User:Pass admin:admin"
sleep 5 
"Grafana Access IP"
kubectl get svc promgraf-grafana -n monitoring  -o jsonpath="{.status.loadBalancer.ingress[*].ip}"