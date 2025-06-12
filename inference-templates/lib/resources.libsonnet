local helpers = import 'helpers.libsonnet';

{
    deployment(params):: {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: {
            name: params.name,
            labels: {
            app: params.name,
            },
        },
        spec: {
            replicas: params.replicaCount,
            selector: {
            matchLabels: {
                app: params.name,
            },
            },
            template: {
                metadata: {
                    labels: {
                    app: params.name,
                    },
                },
                spec: {
                    restartPolicy: "Always",
                    serviceAccountName: "default",
                    schedulerName: "default-scheduler",
                    enableServiceLinks: false,
                    affinity: {
                    },
                    terminationGracePeriodSeconds: 300,
                    preemptionPolicy: "PreemptLowerPriority",
                    serviceAccount: "default",
                    dnsPolicy: "ClusterFirst",
                    initContainers: helpers.initContainerFor(params.inferenceService.type),
                    containers: helpers.containerFor(params.inferenceService.type, params),
                    volumes: params.volumes,
                    tolerations: params.tolerations,
                },
            },
        },
    },

    service(params):: {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: {
            name: params.name,
            labels: params.labels,
        },
        spec: {
            type: params.service.type,
            ports: [
            {
                port: params.service.port,
                protocol: params.service.protocol,
                name: params.service.portName,
            },
            ],
            selector: {
            app: params.name,
            },
        }
    },

    route(params):: {
        apiVersion: 'route.openshift.io/v1',
        kind: 'Route',
        metadata: {
            name: params.name,
        },
        spec: {
            to: {
            kind: 'Service',
            name: params.name,
            },
            port: {
            targetPort: params.service.portName,
            },
            tls: {
            termination: "edge",
            insecureEdgeTerminationPolicy: "Redirect",
            },
            wildcardPolicy: "None",
        },
    }
}