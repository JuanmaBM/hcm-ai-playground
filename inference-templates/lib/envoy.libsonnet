
{
    route(params):: {
        kind: "Route",
        apiVersion: "route.openshift.io/v1",
        metadata: {
            name: "envoy-" + params.name,
        },
        spec: {
            path: "/",
            to: {
                kind: "Service",
                name: "envoy-" + params.name,
                weight: 100
            },
            port: {
                targetPort: "web"
            },
            tls: {
                termination: "edge",
                insecureEdgeTerminationPolicy: "Redirect"
            },
            wildcardPolicy: "None"
        }
    },

    service(params):: {
        apiVersion: "v1",
        kind: "Service",
        metadata: {
            name: "envoy-" + params.name,
            labels: {
                app: "envoy-" + params.name,
            },
        },
        spec: {
            ports: [
            {
                name: "web",
                port: 8000,
                protocol: "TCP",
            },
            ],
            selector: {
                app: "envoy-" + params.name,
            },
        },
    },

    deployment(params):: {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: {
            name: "envoy-" + params.name,
            labels: {
                app: "envoy-" + params.name,
            },
        },
        spec: {
            replicas: 1,
            selector: {
            matchLabels: {
                app: "envoy-" + params.name,
            },
            },
            template: {
                metadata: {
                    labels: {
                        app: "envoy-" + params.name,
                    },
                },
                spec: {
                    containers: [
                        {
                            name: "envoy",
                            image: "envoyproxy/envoy:v1.25-latest",
                            command: [
                            "/usr/local/bin/envoy",
                            ],
                            args: [
                                "--config-path", "/usr/local/etc/envoy/envoy.yaml",
                                "--service-cluster", "front-proxy",
                                "--log-level", "info",
                                "--component-log-level", "filter:trace,http:debug,router:debug",
                            ],
                            ports: [
                                {
                                    name: "web",
                                    containerPort: 8000,
                                },
                                {
                                    name: "admin",
                                    containerPort: 8001,
                                },
                            ],
                            volumeMounts: [
                                {
                                    name: "config",
                                    mountPath: "/usr/local/etc/envoy",
                                    readOnly: true,
                                },
                            ],
                        },
                    ],
                    volumes: [
                        {
                            name: "config",
                            configMap: {
                                name: "envoy-" + params.name,
                                items: [
                                    {
                                        key: "envoy.yaml",
                                        path: "envoy.yaml",
                                    },
                                ],
                            },
                        },
                    ],
                },
            },
        },
    },

    configmap(params):: {
        apiVersion: "v1",
        kind: "ConfigMap",
        metadata: {
        name: params.name,
        labels: {
            app: params.name,
        },
        },
        data: {
        "envoy.yaml": std.manifestYamlDoc(self._envoyConfig(params)),
        },
    },

    _envoyConfig(params):: {
        static_resources: {
        clusters: [
            {
            name: "authorino",
            connect_timeout: "0.25s",
            type: "STRICT_DNS",
            lb_policy: "ROUND_ROBIN",
            http2_protocol_options: {},
            load_assignment: {
                cluster_name: "authorino",
                endpoints: [{
                lb_endpoints: [{
                    endpoint: {
                    address: {
                        socket_address: {
                        address: "authorino-authorino-authorization",
                        port_value: 50051,
                        },
                    },
                    },
                }],
                }],
            },
            },
            {
            name: "envoy-" + params.name,
            connect_timeout: "0.25s",
            type: "STRICT_DNS",
            lb_policy: "ROUND_ROBIN",
            load_assignment: {
                cluster_name: "envoy-" + params.name,
                endpoints: [{
                lb_endpoints: [{
                    endpoint: {
                    address: {
                        socket_address: {
                        address: params.service.portName,
                        port_value: params.service.port,
                        },
                    },
                    },
                }],
                }],
            },
            },
        ],
        listeners: [
            {
            address: {
                socket_address: {
                address: "0.0.0.0",
                port_value: 8000,
                },
            },
            filter_chains: [
                {
                filters: [
                    {
                    name: "envoy.http_connection_manager",
                    typed_config: {
                        "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                        stat_prefix: "local",
                        use_remote_address: true,
                        route_config: {
                        name: "local_route",
                        virtual_hosts: [
                            {
                            name: "local_service",
                            domains: ["*"],
                            routes: [
                                {
                                match: { prefix: "/" },
                                route: {
                                    cluster: "envoy-" + params.name,
                                },
                                },
                            ],
                            rate_limits: [
                                {
                                actions: [{
                                    metadata: {
                                    metadata_key: {
                                        key: "envoy.filters.http.ext_authz",
                                        path: [
                                        { key: "ext_auth_data" },
                                        { key: "username" },
                                        ],
                                    },
                                    descriptor_key: "user_id",
                                    },
                                }],
                                },
                            ],
                            },
                        ],
                        },
                        http_filters: [
                        {
                            name: "envoy.filters.http.ext_authz",
                            typed_config: {
                                "@type": "type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz",
                                transport_api_version: "V3",
                                failure_mode_allow: false,
                                include_peer_certificate: true,
                                grpc_service: {
                                    envoy_grpc: {
                                    cluster_name: "authorino",
                                    },
                                    timeout: "1s",
                                },
                            },
                        },
                        {
                            name: "envoy.filters.http.ratelimit",
                            typed_config: {
                                "@type": "type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit",
                                domain: "talker-api",
                                failure_mode_deny: false,
                                timeout: "3s",
                                rate_limit_service: {
                                    transport_api_version: "V3",
                                    grpc_service: {
                                        envoy_grpc: {
                                            cluster_name: "limitador",
                                        },
                                    },
                                },
                            },
                        },
                        {
                            name: "envoy.filters.http.router",
                            typed_config: {
                                "@type": "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router",
                            },
                            tracing: params.envoy.tracing,
                        },
                        ],
                    },
                    },
                ],
                },
            ],
            },
        ],
        },
        admin: {
            access_log_path: "/tmp/admin_access.log",
            address: {
                socket_address: {
                address: "0.0.0.0",
                port_value: 8001,
                },
            },
        },
    },
}