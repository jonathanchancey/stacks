helm repo add onedev https://dl.cloudsmith.io/public/onedev/onedev/helm/charts
helm repo update onedev

helm install onedev onedev/onedev -n onedev --create-namespace

helm upgrade onedev onedev/onedev -n onedev --set ingress.enabled=true --set ingress.className=traefik-external --set ingress.host=onedev.fkn.chancey.dev --reuse-values


