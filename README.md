# scaffold
terraform repo for proxmox!

## helm


### nfs
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path
```


## k3s something
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
