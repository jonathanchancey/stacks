# mktxp

## user creation

```shell
/user group add name=mktxp_group policy=api,read
/user add name=mktxp_user group=mktxp_group password=mktxp_user_password
```

## ssl
```shell
kubectl get secret he-sw-01-chancey-dev-tls -o jsonpath='{.data.pkcs12\.p12}' | base64 -d > cert.p12
kubectl get secret he-sw-02-chancey-dev-tls -o jsonpath='{.data.pkcs12\.p12}' | base64 -d > cert-he-sw-02.p12
```

<https://github.com/akpw/mktxp>
