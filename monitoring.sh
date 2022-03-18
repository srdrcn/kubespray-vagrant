#!/bin/sh

git clone https://github.com/srdrcn/kubespray-vagrant
echo "### Install Helm3"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sleep 5
echo "### Install Prometheus-Grafana Stack"
cd kubespray-vagrant/kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
sleep 5
kubectl create ns monitoring
helm install promgraf  prometheus-community/kube-prometheus-stack -n monitoring  --values values.yml
sleep 5
kubectl --namespace monitoring patch svc promgraf-grafana -p '{"spec": {"type": "NodePort"}}'
echo "###Grafana User:Pass admin:admin"
kubectl get svc promgraf-grafana -n monitoring
