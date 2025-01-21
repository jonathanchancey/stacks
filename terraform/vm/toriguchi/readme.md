# toriguchi

Netbird Routing Peer

> 鳥口 - bird entrance

source: I made it up

## netbird post provision

```shell
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
curl -sSL https://pkgs.netbird.io/debian/public.key | sudo gpg --dearmor --output /usr/share/keyrings/netbird-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' | sudo tee /etc/apt/sources.list.d/netbird.list
sudo apt-get update
sudo apt-get install netbird
```
https://docs.netbird.io/how-to/installation

## netbird post post provision
disable login expiration in control panel
