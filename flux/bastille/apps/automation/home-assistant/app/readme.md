# readme

yeah man it's late
```
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.131.128.0/18   # native L2 range from your Helm values
    - 10.12.0.0/25      # BGP load-balancer pool
    - 10.244.0.0/16     # pod CIDR
```
