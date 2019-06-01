## Blackbox export of application metrics in Kubernetes using Grok Exporter and Prometheus

### Intro

In order to gain better understanding on how our applications behaves in the realtime on specific environment and to be able to pinpoint and alert possible problems that may occur either with system or the application itself, we must continually create telemetry which is, in plain words, process of automatic generation and transmission of data to some system where it will be monitored and analyzed. One of the preferred monitoring tools is Prometheus.

In the context of application monitoring usually, we think about exporting certain application metrics from the application source code itself. This method is often referred to as a white box monitoring. While this is usually prefered way of doing things, sometimes this approach is not possible (in other words, changes in the code itself are not acceptable, you don't have access to source code, you are using third party service which you depend upon..etc.)

In these situations, only way to get some knowledge about behaviour of the application is by observing application logs and use them to acquire metrics. This approach is usually referred to as a black box monitoring. Fortunately, this is also possible using Prometheus with additional metric exporters. One of the most popular is Grok exporter.

These days, more and more applications are running as microservices in Kubernetes ecosystem which is becoming de-facto standard for orchestration of containerized applications. In this article, I will focus on explaining how you can export metrics from the application logs using Grok exporter and Prometheus in Kubernetes and also explain difference between exporting metrics from the running application in contrast to exporting metrics from application running as a cron job (this especially becomes a bit more challenging to implement when working in Kubernetes ecosystem).

### Deploying Prometheus in Kubernetes

Before we go into the application part, we must first make sure that we have Prometheus running in Kubernetes. This can be done by applying following kubernetes resources:
- prometheus-configmap - contains prometheus config file which will be dynamically loaded into the running Prometheus pod. As you can see, it contains one scrape config defined which points to the grok service running in Kubernetes (later, we will deploy grok exporter in Kubernetes also)
- prometheus-deployment - this is Kubernetes deployment resource which defined one Prometheus pod replica that will be deployed. For the sake of simplicity, we will not take into the consideration persistence of Prometheus data, but this is something that should definitely be done in production usage. In that case, usually, statefulset will be better fit than deployment which would contain persistence volume solution (some nfs storage, local storage, block storage...etc.)
- prometheus-service - this is Kubernetes NodePort service resource which exposes external Prometheus port on all Kubernetes cluster node through which external access to Prometheus dashboard will be available. In the production environment, you would put load balancer/ingress in front of Prometheus application and enable SSL termination but that is out of the scope for this article
