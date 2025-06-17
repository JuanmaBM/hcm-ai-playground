// params.libsonnet
local name = "mistral-small";

{
  name: name,
  replicaCount: 1,

  inferenceService: {
    type: "simulator",  // or "vllm"
    model: "inference-simulator",
  },

  envoy: {
    tracing: {}
  },

  auth: {
    hostname: "*",
  },

  serviceAccount: {
    create: false,
    automount: true,
    annotations: {},
    name: "",
  },

  labels: {
    app: name,
  },

  service: {
    port: 8081,
    type: "ClusterIP",
    portName: "mistrall-small-http",
    protocol: "TCP",
    targetPort: "http",
  },

  resources: {
    limits: {
      cpu: "1",
      memory: "1Gi",
    },
    requests: {
      cpu: "500m",
      memory: "512Mi",
    },
  },

  livenessProbe: {
    httpGet: {
      path: "/v1/models",
      port: "http",
    },
  },

  readinessProbe: {
    httpGet: {
      path: "/v1/models",
      port: "http",
    },
  },

  tolerations: [
    // {
    //   key: "nvidia.com/gpu",
    //   operator: "Exists",
    //   effect: "NoSchedule",
    // },
    // {
    //   key: "nvidia-gpu-only",
    //   operator: "Exists",
    //   effect: "NoSchedule",
    // },
    // {
    //   key: "nvidia.com/gpu",
    //   operator: "Equal",
    //   value: "L40S",
    //   effect: "NoSchedule",
    // },
  ],

  affinity: {
    // podAntiAffinity: {
    //   preferredDuringSchedulingIgnoredDuringExecution: [
    //     {
    //       weight: 100,
    //       podAffinityTerm: {
    //         labelSelector: {
    //           matchLabels: {
    //           },
    //         },
    //         topologyKey: "kubernetes.io/hostname",
    //       },
    //     },
    //   ],
    // },
  },

  volumes: [
    // {
    //   name: "workload-socket",
    //   emptyDir: {}
    // },
    // {
    //   name: "credential-socket",
    //   emptyDir: {}
    // },
    // {
    //   name: "workload-certs",
    //   emptyDir: {}
    // },
    // {
    //   name: "shm",
    //   emptyDir: {
    //     medium: "Memory",
    //     sizeLimit: "2Gi"
    //   }
    // },
    // {
    //   name: "kserve-provision-location",
    //   emptyDir: {}
    // }
  ],

  nodeSelector: {},

  annotations: {},
}