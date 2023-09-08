# scaffold
terraform repo for proxmox!



```bash
curl -sfL https://get.k3s.io | sh -s - server \
--token=YOUR-SECRET \
--tls-san your-dns-name --tls-san your-lb-ip-address \
--cluster-init

curl -sfL https://get.k3s.io | sh -s - server \
--token=YOUR-SECRET \
--tls-san your-dns-name --tls-san your-lb-ip-address \
--server https://IP-OF-THE-FIRST-SERVER:6443

curl -sfL https://get.k3s.io | sh -s - agent \
--server https://your-lb-ip-address:6443 \
--token YOUR-SECRET
```


WARN: iothread is only valid with virtio disk or virtio-scsi-single controller, ignoring
