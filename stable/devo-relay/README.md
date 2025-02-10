# Devo Relay Helm chart

Devo Relay Helm chart for Kubernetes.

The aim of this Helm chart is to provide an easy way of deploying and scaling up Devo Relays in k8s.

The Devo Relay controller is a kubernetes StatefulSet that allows you to manage multiple replicas and persistent state.

**Note**: If you are not an experienced user in the Relay or k8s, please take your time to read the official documentation for the [Relay](https://docs.devo.com/space/latest/96468993/Devo+Relay) and [k8s](https://kubernetes.io/docs/concepts/overview/)
before trying to install it in Kubernetes.

## TL;DR

```console
$ helm repo add devo https://charts.devo.com
$ helm install devo-relay devo/devo-relay -f your-values.yaml --namespace devo-relay --create-namespace
```

The `your-values.yaml` file is a Helm values file based on the template (`values.yaml`) in this repository.

## Requirements

- k8s 1.28+
- Helm v3

## Recommendations

- We recommend the usage of k8s managed services like EKS, AKS or GKS, so that avoiding the burden of installing, managing, monitoring, etc. a Kubernetes cluster.
- All relays managed by the same StatefulSet controller must have the same configuration, that is, when you install a Helm
release of this chart, all replicas must have the same configuration to avoid data balancing issues.

## Install

Add the Devo repository to Helm:

```console
$ helm repo add devo https://charts.devo.com
```

Before installing you need to configure [storage](#storage-volumes-and-buffers).

Install the Devo Relay in a new k8s namespace:

```console
$ helm install devo-relay devo/devo-relay -f your-values.yaml --namespace devo-relay --create-namespace
```

## Upgrade

The Relay doesn't receive security updates automatically. You need to manually upgrade to a newer version when it becomes available.

You can upgrade using `helm upgrade`, for example:

```console
$ helm upgrade <release-name> <chart> -n <namespace> --reuse-values
```

## Uninstall

To remove the Devo Relay from your Kubernetes cluster, run the following command:

```console
$ helm uninstall -n <namespace> <release-name>
```

This command automatically deletes all deployed resources associated with the installation of this Helm chart.

## Storage volumes and buffers

In Kubernetes the PersistentVolume API abstracts details of how storage is provided from how it is consumed, that is, when you need persistent storage you create a persistent volume.

The relay uses disk buffering for storing events when the connection with the target collector is lost or under high load conditions. These should be temporary and you should configure
the buffer parameters in the webapp according your [EPS, expected maximum downtime and recovery mechanism](https://docs.devo.com/space/latest/96469650/Relay+buffers).

**We recommend the use of elastic file systems like EFS for relay storage because it is more cost-efficient if you deploy multiple replicas with gigabytes of disk buffer that is never used.**

You can check the `examples` directory to see ways of setting up different storage systems.

## Rules and ports

When you create a rule from the webapp the ports are automatically open in the relay's containers. If you want to make them accesible for load balancing you have to modify the `Service`
values in the `values.yaml` file to expose the needed ports under the Service IP. These ports are indicated in `loadBalancerInternal.ports` and `loadBalancerPublic.ports`.

## Load Balancing connections between pods

We provide two k8s services to be able to route and balance traffic internally or publicly, `loadBalancerInternal` and `loadBalancerPublic` respectively. They are disabled by
default.

If you want to expose your cluster externally you have to define the `loadBalancerPublic.loadBalancerClass` for provisioning a k8s `Service` of `LoadBalancer` type. Depending on
your cloud provider you will have to install a load balancer controller, configure annotations, etc.

External AWS Load Balancer example:

```yaml
loadBalancerPublic:
  enabled: true
  loadBalancerClass: service.k8s.aws/nlb
  annotations:
    # AWS Network Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "preserve_client_ip.enabled=true"
  ports:
    - protocol: TCP
      PORT: 14001
    - protocol: TCP
      PORT: 14002
```

## Memory and CPU

As the Relay is a Java application the recommended way of managing resources is by using the container requests and limits, you can set them
in the values file. By default, the `-XX:MaxRAMPercentage=80` allows us to be conservative and allow enough memory for the OS.

The requests and limits values depend on your use case and the EPS (Events per Second) or filtering requirements. The relay requires at least ~400 MiB
and 1 cpu to work. By default, the requests are 2 Gi and 2 cpus and the limits 8 Gi and 8 cpus.

## Setting up the relay

Once you install this chart and deploy multiple relay replicas it is necessary to configure them, to do so, you have
several alternatives.

### Interactive mode: Using Devo Relay CLI

To set up the Relay you have to use the Relay CLI. The Relay container must be accessible remotely (port 12998) from the machine where CLI is executed.

You can also use kubectl to run a docker image in the k8s cluster:

```console
$ kubectl run devo-ng-relay-cli -i --tty --rm --image=devoinc/devo-ng-relay-cli:$IMAGE_TAG -- --host=$RELAY_HOST
```

The following variables should be replaced with your value:

- **IMAGE_TAG**: you can choose from the available tags in dockerhub repository.

- **RELAY_HOST**: the pod IP or a kubernetes service name where the relay pod and port 12998 is published.

### Non-interactive mode: Using the Autosetup k8s job

The Autosetup job is a Helm template that is rendered when you set the `autosetup.enable` value to `true`.

For example:

```bash
$ helm template -s templates/autosetup/autosetup.yaml --set autosetup.enable=true . > autosetup-kubectl.yaml
$ kubectl apply -n devo-ng-relay -f autosetup-kubectl.yaml
```

After rendering the template you can create the k8s job object in the cluster with `kubectl apply`.

The `autosetup` key in the `values.yaml` file contains all the values related to this job like the job parameters,
relay configuration parameters, etc.

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### Relay keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| relay.affinity | object | `{}` |  |
| relay.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| relay.environmentVariables[0].name | string | `"JAVA_OPTS"` |  |
| relay.environmentVariables[0].value | string | `"-XX:MaxRAMPercentage=80"` |  |
| relay.fullnameOverride | string | `""` | Completely replaces the generated name. See _helpers.tpl file More info: https://stackoverflow.com/a/63839389   |
| relay.image.pullPolicy | string | `"IfNotPresent"` |  |
| relay.image.repository | string | `"devoinc/devo-ng-relay"` |  |
| relay.image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| relay.imagePullSecrets | list | `[]` |  |
| relay.initConfMountPath | string | `"/relay-conf"` |  |
| relay.livenessProbe | object | `{}` |  |
| relay.loadBalancerInternal.enabled | bool | `false` |  |
| relay.loadBalancerInternal.ports | list | `[]` |  |
| relay.loadBalancerPublic.annotations."service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" | string | `"ip"` |  |
| relay.loadBalancerPublic.annotations."service.beta.kubernetes.io/aws-load-balancer-scheme" | string | `"internet-facing"` |  |
| relay.loadBalancerPublic.annotations."service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" | string | `"preserve_client_ip.enabled=true"` |  |
| relay.loadBalancerPublic.enabled | bool | `false` |  |
| relay.loadBalancerPublic.loadBalancerClass | string | `"service.k8s.aws/nlb"` |  |
| relay.loadBalancerPublic.ports | list | `[]` |  |
| relay.nameOverride | string | `""` | Replaces the name of the chart in the Chart.yaml file. See _helpers.tpl file More info: https://stackoverflow.com/a/63839389 |
| relay.nodeSelector | object | `{}` |  |
| relay.podAnnotations | object | `{}` |  |
| relay.podLabels | object | `{}` |  |
| relay.podSecurityContext.fsGroup | int | `2000` |  |
| relay.podSecurityContext.runAsGroup | int | `2000` |  |
| relay.podSecurityContext.runAsUser | int | `2000` |  |
| relay.readinessProbe | object | `{}` |  |
| relay.replicaCount | int | `1` |  |
| relay.resources.limits.cpu | int | `8` |  |
| relay.resources.limits.memory | string | `"8Gi"` |  |
| relay.resources.requests.cpu | int | `2` |  |
| relay.resources.requests.memory | string | `"2Gi"` |  |
| relay.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| relay.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| relay.serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| relay.tolerations | list | `[]` |  |
| relay.volumeClaimTemplates[0].metadata.name | string | `"data"` |  |
| relay.volumeClaimTemplates[0].spec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| relay.volumeClaimTemplates[0].spec.resources.requests.storage | string | `"10Mi"` |  |
| relay.volumeClaimTemplates[0].spec.storageClassName | string | `"efs-relay"` |  |
| relay.volumeMountsInit[0].mountPath | string | `"/relay-conf"` |  |
| relay.volumeMountsInit[0].name | string | `"data"` |  |
| relay.volumeMountsInit[0].subPathExpr | string | `"$(POD_NAME)/conf"` |  |
| relay.volumeMounts[0].mountPath | string | `"/opt/devo/ng-relay/conf"` |  |
| relay.volumeMounts[0].name | string | `"data"` |  |
| relay.volumeMounts[0].subPathExpr | string | `"$(POD_NAME)/conf"` |  |
| relay.volumeMounts[1].mountPath | string | `"/var/logt"` |  |
| relay.volumeMounts[1].name | string | `"data"` |  |
| relay.volumeMounts[1].subPathExpr | string | `"$(POD_NAME)/varlogt"` |  |

### Autosetup keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autosetup.cleanupAfterFinishedSeconds | int | `20` | Clean up job after finished  (Required) |
| autosetup.config.apiKey | string | `nil` | API Key (Required) Environment variable name: AUTOSETUP_RELAY_API_KEY |
| autosetup.config.apiSecret | string | `nil` | API Secret (Required) Environment variable name: AUTOSETUP_RELAY_API_SECRET |
| autosetup.config.cloud | string |  | Cloud (Not Required). Valid values are: AWS_US, AWS_EU, AWS_CA, APAC, AWS_US3, MANUAL |
| autosetup.config.devoEventLoadBalancerHost | string | `nil` | Collector endpoint (Required if cloud is not specified or cloud is MANUAL)   |
| autosetup.config.devoEventLoadBalancerPort | string | `nil` | Collector port (Required if cloud is not specified or cloud is MANUAL) |
| autosetup.config.enableImpersonation | string | `nil` | Enable/disable impersonation (Not Required) (Default: false) |
| autosetup.config.proxyHost | string | `nil` | Proxy host (Not Required) |
| autosetup.config.proxyPassword | string | `nil` | Proxy password (Not Required) Environment variable name: AUTOSETUP_RELAY_PROXY_PASS |
| autosetup.config.proxyPort | string | `nil` | Proxy port (Required if proxy host has value) |
| autosetup.config.proxyUsername | string | `nil` | Proxy username (Not Required) Environment variable name: AUTOSETUP_RELAY_PROXY_USER |
| autosetup.config.queryApiUri | string | `nil` | Query API URI (Required if cloud is not specified or cloud is MANUAL) |
| autosetup.config.relayApiUri | string | `nil` | Relay API URI (Required if cloud is not specified or cloud is MANUAL) |
| autosetup.config.relayName | string | `nil` | Relay name (Not Required) (Default: <AUTOSETUP_RELAY_NAME>) The placeholder <AUTOSETUP_RELAY_NAME> allows setting up the name dinamically for each replica by using the 'relayNamePrefix' value. If you use a fixed value you have to set up the relay name manually for each replica, that is, firstPodIndex |
| autosetup.configmapName | string | `nil` | Name used for autosetup.properties configmap (Not Required) (Default: "relay-autosetup-config") |
| autosetup.enable | bool | `false` | Enable or disable the autosetup yaml generation |
| autosetup.environmentVariables | list | `[]` | Environment variables for secrets like apikey, proxyPass... See below environment variable name for each autosetup property |
| autosetup.firstPodIndex | int | `0` | First relay pod index where applying autosetup (Required) |
| autosetup.force | bool | `false` | Force setup when relay already exists (Not Required) (Default: false) |
| autosetup.image.repository | string | `"devoinc/devo-ng-relay-cli"` | Relay CLI image used for autosetup (Required) |
| autosetup.image.tag | string | `"1.6.1"` |  |
| autosetup.jobName | string | `nil` | Job name.  (Not Required) (Default: relay-autosetup-<randomString>) |
| autosetup.numberOfJobs | int | `1` | Defineks the number of relays you want to set up by starting in the firstPodIndex. For example, if you set 3 and firstPodIndex: 0, then you will launch three autosetups jobs, for pods 0, 1 and 2.  (Required) |
| autosetup.parallelism | int | `1` | Max number of autosetup jobs to execute in parallel (Required) |
| autosetup.podNamePrefix | string | `"devo-relay"` | Pod name prefix without index number  e.g if pod name is "relay-0", podNamePrefix is "relay" You can get it from "$ kubectl get pods -n <relayNamespace>" (Required) |
| autosetup.relayNamePrefix | string | `nil` | Prefix for <AUTOSETUP_RELAY_NAME>  The name will be completed with the pod index number. If prefix: "relay", names in the web will be relay-0, relay-1, ... (Not Required) (Default: "relay") |
| autosetup.serviceDomain | string | `nil` | Network domain name to be able to connect to pods by name instead of IP  You can get it from "$ kubectl get services -n <relayNamespace>" (Required) |

## How to inspect EFS directories

You can create a file `efs.yaml` with the following k8s objects and use kubectl to create them in k8s.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-inspector-pv
spec:
  storageClassName: <EFS_STORAGE_CLASS_NAME>
  accessModes:
    - ReadWriteMany 
  volumeMode: Filesystem
  capacity:
    storage: 10Mi
  csi:
    driver: efs.csi.aws.com
    volumeHandle: <EFS_ID>:/
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-inspector-pvc
spec:
  storageClassName: <EFS_STORAGE_CLASS_NAME>
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-inspector
spec:
  volumes:
    - name: efs-inspector-pv
      persistentVolumeClaim:
        claimName: efs-inspector-pvc
  containers:       
    - name: efs-inspector
      image: ubuntu
      command: ["bash", "-c", "sleep 600"]
      restartPolicy: Never
      volumeMounts:
        - name: efs-inspector-pv
          mountPath: "/efs-root"
```

```console
$ kubectl apply -n devo-relay -f efs.yaml
$ kubectl exec --stdin --tty efs-inspector -- /bin/bash # open a shell to inspect the file system
```
