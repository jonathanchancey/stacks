


helm repo add truecharts https://charts.truecharts.org/

kubectl create namespace omada

helm install omada-controller truecharts/omada-controller --version 10.1.0
helm upgrade omada-controller truecharts/omada-controller --version 10.1.0 --values=values.yaml

helm uninstall omada-controller