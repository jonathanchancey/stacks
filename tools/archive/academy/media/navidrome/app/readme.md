# navidrome

```bash
kubectl create ns navidrome
kubens navidrome
kubectl create secret generic smbcreds-navidrome --from-literal username=username --from-literal password="password"
```

truenas cobria removed smb "additional parameters" which means we can't force user or group so nfs share must only be used by ladybug user or navidrome won't have permissions
source: https://www.truenas.com/community/threads/auxiliary-parameters-missed.113938/page-3
