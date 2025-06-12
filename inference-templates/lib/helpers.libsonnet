{
    initContainerFor: function(type) 
        if type == "vllm" then [
            {
                name: "storage-initializer",
                image: "quay.io/modh/kserve-storage-initializer@sha256:d361e822b8db152f431d7be48ad5afb6e459497e61441da9db961a63d5e7b242",
                imagePullPolicy: "IfNotPresent",
                args: [
                    "s3://hcm-ai-test1/models-maas/models--mistralai--Mistral-7B-Instruct-v0.3/",
                    "/mnt/models",
                ],
                terminationMessagePath: "/dev/termination-log",
                terminationMessagePolicy: "FallbackToLogsOnError",
                resources: {
                limits: {
                    cpu: "1",
                    memory: "1Gi",
                },
                requests: {
                    cpu: "100m",
                    memory: "100Mi",
                },
                },
                env: [
                {
                    name: "STORAGE_CONFIG",
                    valueFrom: {
                        secretKeyRef: {
                            name: "storage-config",
                            key: "models",
                        },
                    },
                },
                ],
                volumeMounts: [
                {
                    name: "kserve-provision-location",
                    mountPath: "/mnt/models",
                },
                ],
            }
        ]
        else if type == "simulator" then []
        else error "Unsupported inference type: " + type,


    containerFor: function(type, params) 
        if type == "vllm" then [
            {
                name: "inference-service",
                image: "quay.io/modh/vllm@sha256:4f1f6b5738b311332b2bc786ea71259872e570081807592d97b4bd4cb65c4be1",
                imagePullPolicy: "IfNotPresent",
                command: [
                    "python",
                    "-m",
                    "vllm.entrypoints.openai.api_server"
                ],
                args: [
                    "--port=" + params.service.port,
                    "--model=/mnt/models",
                    "--served-model-name=" + params.inferenceService.model,
                    "--max-model-len=20480",
                    "--gpu-memory-utilization=0.95"
                ],
                ports: [
                    {
                    name: "http",
                    containerPort: params.service.port,
                    protocol: "TCP"
                    }
                ],
                terminationMessagePath: "/dev/termination-log",
                terminationMessagePolicy: "FallbackToLogsOnError",
                lifecycle: {
                    preStop: {
                    httpGet: {
                        path: "/wait-for-drain",
                        port: 8022,
                        scheme: "HTTP"
                    }
                    }
                },
                env: params.envVars,
                resources: params.resources,
                volumeMounts: params.volumeMounts,
                livenessProbe: params.livenessProbe,
                readinessProbe: params.readinessProbe,
            }
        ]
        else if type == "simulator" then [
            {
                terminationMessagePath: "/dev/termination-log",
                name: "inference-simulator",
                ports: [
                    {
                    name: "http",
                    containerPort: params.service.port,
                    protocol: "TCP",
                    }
                ],
                imagePullPolicy: "IfNotPresent",
                terminationMessagePolicy: "FallbackToLogsOnError",
                image: "quay.io/jbarea/llm-d-inference-sim:v0.1.1",
                args: [
                    "--port=" + params.service.port,
                    "--model=" + params.inferenceService.model,
                ],
                resources: params.resources,
                livenessProbe: params.livenessProbe,
                readinessProbe: params.readinessProbe,
            }
        ]
        else error "Unsupported inference type: " + type
    

}