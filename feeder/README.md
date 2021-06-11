## Feeder-service Manual Deployment

#### Install Chart

```
helm install <chart-name> feeder-service \
     -n <namespace>
```

#### Upgrade Chart

```
helm upgrade <chart-name> feedee-service \
     -n <namespace>
```
---

## Install and Upgrade with latest image build (Cilium testing Purpose)

#### Install Chart

```
helm install feeder-service-cilium charts -n feeder-service-cilium --set image=gcr.io/accuknox/node-event-feeder:111
```

#### Upgrade Chart

```
helm upgrade feeder-service-cilium charts -n feeder-service-cilium --set image=gcr.io/accuknox/node-event-feeder:111
```
- Note: gcr.io/accuknox/node-event-feeder:111 is the latest build
- Incase of making changes in the application code, new image can be built and set the image name in helm install/upgrade command

#### Respective Topic names for this latest build
- cilium-telemetry-test
- cilium-alerts-test
