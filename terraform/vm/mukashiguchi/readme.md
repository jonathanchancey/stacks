# mukashiguchi

Zerotier Routing Peer

> 昔口 - entrance from the olden days

source: I made it up

## zerotier install

```shell
sudo apt-get update
sudo apt-get -y full-upgrade && sudo reboot
sudo apt-get install ca-certificates curl gnupg -y
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
sudo apt-get update
sudo apt-get install zerotier-one
```

https://docs.zerotier.com/exitnode/#setup
https://docs.zerotier.com/route-between-phys-and-virt/