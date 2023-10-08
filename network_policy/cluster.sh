eksctl create cluster --name coolbet --without-nodegroup
kubectl delete daemonset -n kube-system aws-node
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
kubectl create -f - <<EOF
kind: Installation
apiVersion: operator.tigera.io/v1
metadata:
  name: default
spec:
  kubernetesProvider: EKS
  cni:
    type: Calico
  calicoNetwork:
    bgp: Disabled
EOF

eksctl create nodegroup --cluster coolbet --node-type t3.medium --max-pods-per-node 100
aws eks update-kubeconfig --region us-east-1 --name coolbet