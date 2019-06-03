## Blackbox export of application metrics in Kubernetes using Grok Exporter and Prometheus

### Intro

In order to gain a better understanding of how our applications behave in realtime and to be able to pinpoint and alert the possible problems that may occur, we must continually create telemetry. Telemetry is, in plain words, the process of automatic generation and the transmission of data to some system where it will be monitored and analyzed. One of the preferred monitoring tools is **Prometheus**.

In the context of application monitoring, we usually think about exporting certain application metrics from the application source code itself. This method is often referred to as **white box monitoring**. While this is usually the prefered method, sometimes, this approach is not possible (for example: you don't have access to make changes in the source code, you are using a third party service which you depend upon, etc.)

In these situations, the only way to gain some knowledge about the behaviour of the application is by observing application logs and using them to construct metrics. This approach is usually referred to as **black box monitoring**. Fortunately, this is also possible using Prometheus with additional metric exporters. One of the most popular is **Grok exporter**.

These days, more and more applications are running as microservices in the **Kubernetes** ecosystem which is becoming a de-facto standard for the orchestration of containerized applications. In this article, I will focus on explaining how you can export metrics from the application logs using Grok exporter and Prometheus in Kubernetes. I will also explain the difference between exporting metrics from the running application in contrast to exporting metrics from the application running as a cron job (this especially becomes a bit more challenging to implement when working in the Kubernetes ecosystem).

This guide assumes you already have the Kubernetes cluster running. For experimentation purposes, you can deploy Kubernetes on your local machine using [minikube](https://kubernetes.io/docs/setup/minikube/) 

### Deploying Prometheus in Kubernetes

Before we go into the application part, we need to make sure that we have Prometheus running in Kubernetes. This can be done using the following Kubernetes resources:

- [prometheus-configmap](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/prometheus/prometheus-configmap.yaml) - contains a prometheus config file which defines one scrape config which points to the Grok exporter service running in Kubernetes (later, we will aso deploy Grok exporter in Kubernetes)
- [prometheus-deployment](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/prometheus/prometheus-deployment.yaml) - this is a Kubernetes deployment resource which defined one Prometheus pod replica that will be deployed. In the production environment, you would define persistence for the Prometheus data, but that is beyond the scope of this article
- [prometheus-service](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/prometheus/prometheus-service.yaml) - this is a Kubernetes NodePort service resource which exposes the external Prometheus port on all Kubernetes cluster nodes through which external access to Prometheus dashboard will be available. In the production environment, you would put load balancer/ingress in front of the Prometheus application and enable SSL termination but that too is beyond the scope of this article

We will first create a namespace called `app-monitoring` and then apply the resources from above:
```
$ kubectl create namespace app-monitoring

cd ./prometheus
prometheus $ kubectl apply prometheus-configmap.yaml
prometheus $ kubectl apply prometheus-deployment.yaml
prometheus $ kubectl apply prometheus-service.yaml

prometheus $ kubectl get deployment,pod,svc -n app-monitoring
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/prometheus   1/1     1            1           65s

NAME                              READY   STATUS    RESTARTS   AGE
pod/prometheus-5dc98b454f-4kzwv   1/1     Running   0          53s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/prometheus      NodePort    10.105.102.60   <none>        9090:31100/TCP   22d
```

When we apply these resources, you should be able to access Prometheus dashboard through your browser: `http://<HOST>:31100`

### Example application

Now that we have Prometheus up and running, next thing to do is to consider how we are going to run the application from which we will scrape metrics using Grok exporter and pull them from Prometheus.

For the purpose of making this article clearer and focused on the problem of blackbox monitoring, I've created a small "application" which just logs information which we will scrape to get metrics. The idea is to dockerize this application and run it in a Kubernetes environment.

Format of logged metrics looks like this:
```
| ACNTST_C: 66 | ACNTST_C_HVA: 53 | ACTIVE_PINGS: 21 | B_WRITERS: 55 |
```

Our assignment is to scrape values for each 4 metrics and push them to the Prometheus and then have the ability to show them as **Prometheus GAUGE metric** on the Prometheus. In contrast to **COUNTER**, which is a cumulative metric, **GAUGE** is a metric that represents a single numerical value that can arbitrarily go up and down. This way, we would be able to track how metric values are changing in the function of time.
There are two possible scenarios in which this application is running: continually running application and application running as a cron job. This article will show both approaches in the context of exporting metrics from the logs.

### Grok exporter

To be able to export metrics in the blackbox fashion, we are using the [Grok Exporter tool](https://github.com/fstab/grok_exporter) which is a generic Prometheus exporter that extracts metrics from unstructured log data. Grok exporter uses Grok patterns for parsing log lines.

Before we dockerize and deploy the example application in Kubernetes, we must first apply the following Grok exporter Kubernetes resources:
- [grok-exporter-configmap](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/grok_exporter/grok-exporter-configmap.yaml) - contains a configuration file for the Grok exporter which contains the following key information: 
  - input - path to the log that will be scraped
  - Grok - configures location of Grok pattern definitions
  - metrics - defines which metrics we want to scrape from the application log
  - server - configures HTTP port
- [grok-exporter-service](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/grok_exporter/grok-exporter-service.yaml) - Kubernetes ClusterIP service that will be exposed internally in the Kubernetes cluster so that the Grok exporter is available from the Prometheus

We can apply these resources using following kubectl commands:
```
cd ./grok_exporter
grok_exporter $ kubectl apply grok-exporter-configmap.yaml
grok_exporter $ kubectl apply grok-exporter-service.yaml
```

### Scraping metrics from the continually running application

We will first look at how to scrape metrics from the running application. We need to do the following:
- run application which is writing data to the application log file
- run Grok exporter which takes data from the application log file, and based on the rules that we define, makes data available to Prometheus
- we already have Prometheus running and listening to the Grok exporter service for incomming metrics

The application can be found [here](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/example_application/example_application.rb). The application takes two arguments: number of times it will generate output with random values, output log where data will be stored. 
The dockerfile for this application is defined [here](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/example_application/Dockerfile)

We will dockerize our application by simply doing this: 
```
cd ./example_application
example_application $ docker build -t example-application .
```

Now that we have the application docker image, it is time to use it in the Kubernetes deployment resource defined in the file: [example-application-deployment](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/example_application/example-application-deployment.yaml)

If we observe this file more carefully, we will see that pod contains two containers: **example-application** and **grok-exporter**. The usual scenario in Kubernetes, where one pod has multiple containers, is the case where one of them is a sidecontainer which needs to take output of the main running application container and do something with it (in our case, it needs to take log output and pass it to the Grok exporter application which will, based on the rules defined, scrape metrics for Prometheus)

To be able to do this, the important thing to know is that the **containers running in the same pod are sharing the same volume** which means that we can mount volume on each container and, thus, enable sharing of the files between them. For this purpose we are using a Volume called **emptyDir** which is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that Node. Containers in the Pod can all read and write the same files in the emptyDir volume. This basically means that while the example-application is logging information in the output log, that log is simultaneosly read by the grok-exporter.

Let's apply this resource in Kubernetes:
```
cd ./example_application
example_application $ kubectl apply -f example-application-deployment.yaml
example_application $ kubectl get pods -n app-monitoring | grep example-application
example-application-5d594c6bd-8c8ml   2/2     Running   0          71s
```

If we open Prometheus dashboard `http://<HOST>:31100`, we can search 4 metrics that we created from application logs. You should be able to see them and show values in the graph. For example, for metric ACNTST_C, the graph can look like this:

![prometheus](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/prometheus_graph_1.png)

### Scraping metrics from the application running as cron job

Generally, when you want to run a cron job in Kubernetes, the obvious choice would be to use [CronJob resource type]( https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/). All we would need is to move our containers from Deployment resource to CronJob resource. However, there are a couple of problems with this approach:
- we cannot put the Grok exporter application container into the CronJob as well, since it needs to run constantly
- if we decide to run just the example application in CronJob and the grok-exporter in a separate Pod/Deployment, we encounter a situation where we have two pods which need to access the same Persistence volume which is discouraged practice in the Kubernetes world (collocation of pods, multiple access defined persistent volume types, etc.)

To avoid these problems, we will use the same approach as we did previously for the example-application, but with a significant change in the way we run the application in the container (we will run it inside the container as a cron job). 

To do this, we need the following:

Create bash script called [run_example_application](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/cron_example_application/run_example_application) which runs example_application.rb file

Modify [Dockerfile](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/cron_example_application/Dockerfile) so it looks like this:
```
FROM ruby:2.3.1-alpine
MAINTAINER bakir@atlantbh.com

ENV APP_BASE_DIR /example
ENV APP_LOG_DIR /var/log/cron-example-application
ENV APP_LOG $APP_LOG_DIR/app.log

RUN mkdir -p $APP_BASE_DIR/cron
RUN mkdir -p $APP_LOG_DIR

COPY "./example_application.rb" $APP_BASE_DIR/
COPY "./run_example_application" $APP_BASE_DIR/cron/

RUN chmod a+x $APP_BASE_DIR/example_application.rb
RUN chmod a+x $APP_BASE_DIR/cron/run_example_application

RUN echo -n "* * * * * run-parts ${APP_BASE_DIR}/cron" >> /etc/crontabs/root
RUN touch $APP_LOG

# Run the command on container startup
CMD ["sh", "-c", "crond -f"]
```
As you can see, we are putting **run_example_application** script into the **/example/cron** directory which we will pass as an argument to the **run-parts** command which we put into the **crontab**. run-parts command will run every minute, every script found in the specified directory (in our case that is /example/cron). The important thing to note is that the name of the script must be without type (for example sh) and script must be executable.

Next thing to do is to build this Dockerfile:
```
cd ./cron_example_application
cron_example_application $ docker build -t cron-example-application .
```

Finally, we need to run the [cron-example-application-deployment](https://github.com/ATLANTBH/devops-research/blob/master/blackbox_app_metrics_exporter_with_prometheus_and_k8s/cron_example_application/cron-example-application-deployment.yaml) resource:
```
cd ./cron_example_application
cron_example_application $ kubectl apply -f example-application-deployment.yaml
cron_example_application $ kubectl get pods -n app-monitoring | grep example-application
NAME                                  READY   STATUS    RESTARTS   AGE
example-application-4d192d6bf-4c2fl   2/2     Running   0          13m
```
If we open Prometheus dashboard http://<HOST>:31100, we should be able to see our 4 metrics. 

### Conclusion

There are certain situations where you will not be able to modify code and export metrics like you want. In those cases, you will have to rely on the available application logs in order to construct/gather matrics. I hope this article showed you how it can be done using 
Exporter and Prometheus. Also, since more and more applications are designed as microservices, dockerized and run in the Kubernetes ecosystem, this article showed you how you can establish telemetry in those conditions. Finally, it presented an important difference between continuously and periodically running an application in the context of exporting metrics in the Kubernetes ecosystem.
