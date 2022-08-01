# Setup

### Local
Below are instructions to install StormForge Optimize Live to a local minikube/microk8s cluster.

### 1. First install Kube Prometheus Stack to the cluster
```
helm install prometheus-k8s kube-prometheus-stack \
  --wait \
  --namespace monitoring \
  --create-namespace \
  --repo https://prometheus-community.github.io/helm-charts \
  --set alertmanager.enabled=false \
  --set coreDns.enabled=false
```

### 2. Install Optimize Live to the cluster


Install and Login to the StormForge CLI follow these [instructions](https://docs.stormforge.io/optimize-live/install/#login)

Install Optimize Live charts using prometheus for metrics:
```
helm install optimize-live . \
  --wait \
  --atomic \
  --namespace stormforge-system \
  --create-namespace \
  --set metricsURL=http://prometheus-k8s-kube-promet-prometheus.monitoring.svc:9090 \
  -f <(stormforge generate secret -o helm --name optimize-live)
```


Expose StormForge Grafana service port to visualize history of recommendations
```
kubectl port-forward -n stormforge-system svc/grafana 3000:80
```
