#!/bin/sh

VAGRANT_HOME=/home/vagrant

# configure apt mirror
if [ -n "$APT_REGION" ]; then
  sed -i "s/archive.ubuntu.com/${APT_REGION}.archive.ubuntu.com/g" /etc/apt/sources.list
fi

# install pip
apt-get update && apt-get install -y python3-pip

# clone kubespray kubernetes ver 1.18
git clone -b release-2.14 https://github.com/srdrcn/kubespray.git /opt/kubespray
cd /opt/kubespray

# install required packages
pip3 install -r requirements.txt

# set host network ip
sed -i  's/local_release_dir.*/ipaddr/' inventory/local/hosts.ini
sed -i "s/ipaddr/ip=$IP/" inventory/local/hosts.ini
sed -i "s/node1/$(hostname)/g" inventory/local/hosts.ini

# execute playbook
ansible-playbook \
  -i inventory/local/hosts.ini \
  --become --become-user=root \
  cluster.yml

# apply KUBECONFIG to `vagrant` user
mkdir -p $VAGRANT_HOME/.kube
cp /etc/kubernetes/admin.conf ${VAGRANT_HOME}/.kube/config
chown vagrant ${VAGRANT_HOME}/.kube/config

# export KUBECONFIG for host OS
sed "s/127.0.0.1/$IP/" /etc/kubernetes/admin.conf > /vagrant/kubeconfig_for_host_os


echo "### Install Helm3"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sleep 5
echo "### Install Prometheus-Grafana Stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sleep 5
kubectl create ns monitoring
helm install promgraf  prometheus-community/kube-prometheus-stack -n monitoring
sleep 5
kubectl --namespace monitoring patch svc promgraf-grafana -p '{"spec": {"type": "NodePort"}}'
echo "###Grafana User:Pass
admin:prom-operator"
kubectl get svc promgraf-grafana -n monitoring
kubectl apply -f https://raw.githubusercontent.com/srdrcn/kubespray-vagrant/main/kube-dash/rbac.yml
