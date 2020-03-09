#!/usr/bin/env bash

set -eo pipefail

setup_admin_user() {
  cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system

---
EOF
}

setup_networking() {
  curl https://docs.projectcalico.org/manifests/calico.yaml | kubectl apply -f -
}

setup_client_local() {
  mkdir -p ${HOME}/.kube
  sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
  sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
}

bootstrap_kube() {
  local API_IP="$(hostname -I | awk '{print $1}')"
  if ! [[ "$API_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Unable to get valid kubernetes api ip, aborting!"
    return 1
  fi
  sudo kubeadm init --pod-network-cidr=${POD_CIDR} --apiserver-advertise-address=${API_IP} --ignore-preflight-errors=NumCPU
}

disable_swap() {
  sudo swapoff -a
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

install_kubernetes() {
  sudo apt-get update && sudo apt-get install -y apt-transport-https && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update
  sudo apt install -y kubeadm kubelet kubernetes-cni
}

install_docker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update && sudo apt-get install -y docker-ce
}

main() {
  # Lets install docker
  install_docker || { echo "ERROR: Failed to completely install docker"; exit 1; }
  { (docker -v  && echo "INFO: DOCKER is HERE"); } || { echo "ERROR: Some docker util is missing"; exit 1; }

  # Lets install kubernetes utilities
  install_kubernetes || { echo "ERROR: Failed to completely install kubernetes"; exit 1; }

  # Disable swap https://discuss.kubernetes.io/t/swap-off-why-is-it-necessary/6879
  { (disable_swap && echo "INFO: Done disabling swap"); } || { echo "ERROR: Failed to disable swap"; exit 1; }

  # Bootstrap single node kubernetes cluster
  bootstrap_kube || { echo "ERROR: Failed to completely bootstrap kubernetes node"; exit 1; }

  # Setup non-root kube client
  { (setup_client_local && kubectl version & echo "INFO: KUBECTL is HERE"); } || { echo "ERROR: Some kubernetes util is missing"; exit 1; }

  # Setup k8s cluster networking
  { (setup_networking && echo "INFO: Done setting up cluster networking"); } || { echo "ERROR: Failed to setup k8s cluster networking"; exit 1; }

  # Configure kubernetes master as worker
  kubectl taint nodes --all node-role.kubernetes.io/master- && echo "INFO: Kubernetes single node cluster is ready for use"

  # Setup test admin user
  setup_admin_user || { echo "ERROR: Failed to create test admin user"; exit 1; }
  token="$(kubectl get secret "$(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')" -nkube-system -o jsonpath='{.data.token}' | base64 --decode)"
  echo -e "To connect on your local machince, Run the following command:\n
- kubectl config set-cluster my-k8s --server=https://{PUBLIC_IP}:6443 --insecure-skip-tls-verify\n
- kubectl config set-credentials my-admin-user --token=${token}\n
- kubectl config set-context my-k8s --cluster=my-k8s --user=my-admin-user\n
- kubectl config use-context my-k8s"
}

main
