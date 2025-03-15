# Soler Helm Chart

This Helm chart deploys Soler, a Solana Transaction Loader with both gRPC and HTTP APIs.

## TL;DR

```bash
# Add the repository
helm repo add soler https://your-repo-url.com

# Install the chart with the release name "soler"
helm install soler soler/soler
```

## Introduction

This chart bootstraps a Soler deployment on a Kubernetes cluster using the Helm package manager.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1.0+

## Parameters

### Global parameters

| Name                   | Description                                                                   | Default |
|------------------------|-------------------------------------------------------------------------------|---------|
| `replicaCount`         | Number of Soler replicas to deploy                                            | `1`     |
| `image.repository`     | Soler image repository                                                        | `soler` |
| `image.tag`            | Soler image tag                                                               | `latest`|
| `image.pullPolicy`     | Soler image pull policy                                                       | `IfNotPresent` |
| `imagePullSecrets`     | Image pull secrets                                                            | `[]`    |
| `nameOverride`         | Override chart name                                                           | `""`    |
| `fullnameOverride`     | Override full chart name                                                      | `""`    |

### Configuration parameters

| Name                         | Description                                   | Default                               |
|------------------------------|-----------------------------------------------|---------------------------------------|
| `config.solanaRpcEndpoint`   | Solana RPC endpoint URL                       | `https://api.mainnet-beta.solana.com` |
| `config.useMockData`         | Whether to use mock data                      | `true`                                |

### Deployment parameters

| Name                    | Description                                          | Default                         |
|-------------------------|------------------------------------------------------|----------------------------------|
| `service.type`          | Kubernetes service type                              | `ClusterIP`                      |
| `service.httpPort`      | HTTP port                                            | `8080`                           |
| `service.grpcPort`      | gRPC port                                            | `50051`                          |
| `resources.limits`      | Resource limits                                      | See values.yaml                  |
| `resources.requests`    | Resource requests                                    | See values.yaml                  |
| `autoscaling.enabled`   | Enable autoscaling                                   | `false`                          |
| `autoscaling.minReplicas` | Min replicas for HPA                              | `1`                              |
| `autoscaling.maxReplicas` | Max replicas for HPA                              | `5`                              |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization          | `80`                             |

## Configuration and Installation

### Installing the Chart

To install the chart with the release name `soler`:

```bash
helm install soler ./charts/soler
```

The command deploys Soler on the Kubernetes cluster with the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

### Uninstalling the Chart

To uninstall/delete the `soler` deployment:

```bash
helm delete soler
```