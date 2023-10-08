#!/usr/bin/env bash

PROD_POD_IP=$(kubectl get pods -n prod -o jsonpath="{.items[*].status.podIP}")

SRE_POD_NAME=$(kubectl get pods -n sre -o=jsonpath='{.items[?(@.metadata.labels.app=="nginx")].metadata.name}')

ACCOUNT_POD_NAME=$(kubectl get pods -n accounting -o=jsonpath='{.items[?(@.metadata.labels.app=="nginx")].metadata.name}')

TIMEOUT=10

kubectl apply -f net_pol_2.yaml

echo "----------------------------------------------------------------------------------------"
echo "Attempting to access port 5000 of Pod in Prod namespace with Pod in Accounting Namespace"
echo "________________________________________________________________________________________"

kubectl -n accounting exec $ACCOUNT_POD_NAME -- curl --connect-timeout $TIMEOUT $PROD_POD_IP:5000/api/message

echo "----------------------------------------------------------------------------------------"
echo "Attempting to access port 3000 of Pod in Prod namespace with Pod in Accounting Namespace"
echo "________________________________________________________________________________________"

kubectl -n accounting exec $ACCOUNT_POD_NAME -- curl --connect-timeout $TIMEOUT $PROD_POD_IP:3000

echo "---------------------------------------------------------------------------------"
echo "Attempting to access port 5000 of Pod in Prod namespace with Pod in SRE Namespace"
echo "_________________________________________________________________________________"

kubectl -n sre exec $SRE_POD_NAME -- curl --connect-timeout $TIMEOUT $PROD_POD_IP:5000/api/message

echo "----------------------------------------------------------------------------------"
echo "Attempting to access port 3000 of Pod in Prod namespace with Pod in SRE Namespace"
echo "__________________________________________________________________________________"

kubectl -n sre exec $SRE_POD_NAME -- curl --connect-timeout $TIMEOUT $PROD_POD_IP:3000