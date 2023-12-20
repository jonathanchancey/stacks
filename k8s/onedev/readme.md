helm repo add onedev https://dl.cloudsmith.io/public/onedev/onedev/helm/charts
helm repo update onedev

helm install onedev onedev/onedev -n onedev --create-namespace

helm upgrade onedev onedev/onedev -n onedev --set ingress.enabled=true --set ingress.className=traefik-external --set ingress.host=onedev.fkn.chancey.dev --reuse-values


helm upgrade onedev onedev/onedev -n onedev --values=values.yaml
helm install onedev onedev/onedev -n onedev --values=values.yaml

https://docs.onedev.io/

https://docs.onedev.io/tutorials/code/gitops

npx create-react-app gitops-demo
cd gitops-demo
git remote add origin https://onedev.fkn.chancey.dev/gitops-demo
git push --set-upstream origin master   


check this out later
https://docs.onedev.io/tutorials/code/gitops#set-up-gitops-for-the-demo-project

helm install onedev onedev/onedev -n onedev --create-namespace --set ingress.enabled=true --set ingress.className=traefik-external --set ingress.host=onedev.fkn.chancey.dev --reuse-values

helm upgrade onedev onedev/onedev -n onedev --set ingress.enabled=true --set ingress.className=traefik-external --set ingress.host=onedev.fkn.chancey.dev --reuse-values
