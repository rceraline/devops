```
az aks get-credentials --name aks-01 --resource-group rg-aks-with-terraform-01

kubectl create namespace aks-store

kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/sample-manifests/docs/app-routing/aks-store-deployments-and-services.yaml -n aks-store

kubectl apply -f nginx-internal.yaml

kubectl apply -f ingress.yaml -n aks-store

kubectl delete NginxIngressController default
```
