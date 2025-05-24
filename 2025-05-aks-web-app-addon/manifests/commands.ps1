## Create self signed certificate
az keyvault certificate create --vault-name kv20250524 -n my-certificate -p `@policy.json

## Connect to AKS
az aks get-credentials --name aks-addon-01 --resource-group rg-aks-addon-01

## Deploy test application in aks-store namespace
kubectl create namespace aks-store

kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/sample-manifests/docs/app-routing/aks-store-deployments-and-services.yaml -n aks-store

## Create a NGINX ingress controller called nginx-public
kubectl apply -f nginx-public.yaml -n aks-store

## Create an ingress for our test application that uses the nginx-public ingress controller
kubectl apply -f ingress.yaml -n aks-store

## List all nginx ingress controllers
kubectl get NginxIngressController

## Delete the default NGINX ingress controller that is automatically created
kubectl delete NginxIngressController default
