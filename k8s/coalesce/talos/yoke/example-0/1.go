// This program aims to demonstrate the a flight is nothing more than program that writes resources to stdout.
// The example implementation is not idiomatic, nor does it represent good practices.
// Simply outputting yaml to stdout does not take advantage of our development environment,
// it is however easy to grok and help us understand from a place of familiarity.
package main

import "fmt"

var deployment = `
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  labels:
    app: example-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: example-app
  template:
    metadata:
      labels:
        app: example-app
    spec:
      containers:
      - name: example-app
        image: nginx:latest
        ports:
        - containerPort: 80
`

func main() {
	fmt.Println(deployment)
}
