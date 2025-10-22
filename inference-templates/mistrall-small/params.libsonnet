// params.libsonnet
local name = "mistral-small";

{
  name: name,
  namespace: "mistral-small",
  replicaCount: 1,

  inferenceService: {
    type: "simulator",  // simulator or "vllm"
    model: "inference-simulator",
  },

  envoy: {
    tracing: {}
  },

  auth: {
    hostname: "*",
    apiKey: {
      matchLabels: {
        name: "group",
        value: "friends"
      },
      prefix: "APIKEY"
    }
  },

  labels: {
    app: name,
  },

  envVars: [
    {
      name: "HF_HOME",
      value: "/tmp/hf_home",
    },
    {
      name: "PORT",
      value: "8081",
    },
  ],

  service: {
    port: 8081,
    type: "ClusterIP",
    portName: "mistral-small-http",
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
    {
      key: "nvidia.com/gpu",
      operator: "Exists",
      effect: "NoSchedule",
    },
    {
      key: "nvidia-gpu-only",
      operator: "Exists",
      effect: "NoSchedule",
    }
  ],

  affinity: {},

}