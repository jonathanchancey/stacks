# nextcloud

https://github.com/nextcloud/helm/blob/main/charts/nextcloud/README.md


```zsh
helm repo update
helm repo add nextcloud https://nextcloud.github.io/helm/
helm install --namespace=nextcloud nextcloud nextcloud/nextcloud --values=values.yaml
```

todo
- [ ] add database
- add vault and username/password
  - [ ] actually just use k8s secrets




chipmunk for db

***
```bash
PS C:\Users\seki\git\scaffold\k8s\nextcloud> helm install --namespace=traefik nextcloud nextcloud/nextcloud --values=values.yaml
NAME: nextcloud
LAST DEPLOYED: Tue Nov 21 15:08:08 2023
NAMESPACE: traefik
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
#######################################################################################################
## WARNING: You did not provide an external database host in your 'helm install' call                ##
## Running Nextcloud with the integrated sqlite database is not recommended for production instances ##
#######################################################################################################

For better performance etc. you have to configure nextcloud with a resolvable database
host. To configure nextcloud to use and external database host:


1. Complete your nextcloud deployment by running:

  export APP_HOST=127.0.0.1
  export APP_PASSWORD=$(kubectl get secret --namespace traefik nextcloud -o jsonpath="{.data.nextcloud-password}" | base64 --decode)

  ## PLEASE UPDATE THE EXTERNAL DATABASE CONNECTION PARAMETERS IN THE FOLLOWING COMMAND AS NEEDED ##

  helm upgrade nextcloud nextcloud/nextcloud \
    --set nextcloud.password=$APP_PASSWORD,nextcloud.host=$APP_HOST,service.type=ClusterIP,mariadb.enabled=false,externalDatabase.user=nextcloud,externalDatabase.database=nextcloud,externalDatabase.host=YOUR_EXTERNAL_DATABASE_HOST
```



```php

<?php
$CONFIG = array (
  'trusted_proxies'   => ['10.10.0.40'],
  'overwritehost'     => 'ssl-proxy.tld',
  'overwriteprotocol' => 'https',
  'overwrite.cli.url' => 'https://nextcloud.fkn.chancey.dev/,
);
```



https://metallb.universe.tf/usage/
https://nextcloud.fkn.chancey.dev/

proxmox gecko console
https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/reverse_proxy_configuration.html
https://docs.nextcloud.com/server/21/admin_manual/maintenance/upgrade.html
https://10.10.0.171/index.php/login
https://help.nextcloud.com/t/instance-support-unsecured-url-even-if-traefik-is-setup-with-full-https-redirection/135911/2
https://www.turnkeylinux.org/forum/support/wed-20181121-1119/nextcloud-trusted-domains
https://www.turnkeylinux.org/nextcloud
https://help.nextcloud.com/t/how-to-get-around-access-through-untrusted-domain-error/48179
https://help.nextcloud.com/t/where-is-config-php/54100
https://docs.nextcloud.com/server/27/admin_manual/installation/installation_wizard.html#trusted-domains
