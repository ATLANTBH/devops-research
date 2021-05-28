# Deploy application to Kubernetes with Helm

### About

This helm chart is created in order to give an example for Tech Bite - Deploy application to Kubernetes with Helm. Helm chart is located in `nginx-app` folder together with `values.yaml` file. 

### Install Helm chart

Before installing Helm chart, you should add `./certs-issuer.yaml` resource to your k8s cluster by executing `kubectl apply -f certs-issuer.yaml`. ClusterIssuer is a Kubernetes resource that represent certificate authority which generates signed certificates by honoring certificate signing requests. You should put your email address instead of `example-email@example.com` Let's Encrypt uses this email address to inform you about expiring certificates.

You can install Helm chart by executing the following command:
`helm install nginx-app nginx-app/`

Once you have executed the command above, you can check view the installed resources:
```
mujoh@mujo deploy_application_to_kubernetes_with_helm % kubectl get po,svc,ing
NAME                                         READY   STATUS    RESTARTS   AGE
pod/nginx-app-test-app-ui-744c78c6df-9mhl5   1/1     Running   0          11s

NAME                            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/nginx-app-test-app-ui   ClusterIP   10.0.11.58   <none>        80/TCP    11s

NAME                                       CLASS    HOSTS                           ADDRESS   PORTS     AGE
ingress.extensions/nginx-app-test-app-ui   <none>   test-app.example.com             80, 443   11s
```