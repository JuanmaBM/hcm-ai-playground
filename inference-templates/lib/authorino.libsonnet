{
    instance(params):: {
        apiVersion: "operator.authorino.kuadrant.io/v1beta1",
        kind: "Authorino",
        metadata: {
            name: "authorino",
            namespace: params.namespace
        },
        spec: {
            listener: {
                tls: {
                    enabled: false
                }
            },
            oidcServer: {
                tls: {
                    enabled: false
                }
            }
        }
    },

    config(params):: {
        apiVersion: "authorino.kuadrant.io/v1beta3",
        kind: "AuthConfig",
        metadata: {
            name: "envoy-" + params.name,
            namespace: params.namespace
        },
        spec: {
            authentication: {
                [params.auth.apiKey.matchLabels.value]: {
                    apiKey: {
                        allNamespaces: false,
                        selector: {
                            matchLabels: {
                                [params.auth.apiKey.matchLabels.name]: params.auth.apiKey.matchLabels.value
                            }
                        }
                    },
                    credentials: {
                        authorizationHeader: {
                            prefix: params.auth.apiKey.prefix
                        }
                    },
                    metrics: false,
                    priority: 0
                },
                sso: {
                    credentials: {},
                    jwt: {
                        issuerUrl: "https://sso.redhat.com/auth/realms/redhat-external"
                    },
                    metrics: true,
                    priority: 10
                }
            },
            authorization: {
                apikey: {
                    metrics: false,
                    patternMatching: {
                        patterns: [
                            {
                                operator: "eq",
                                selector: "auth.identity.metadata.labels." + params.auth.apiKey.matchLabels.name,
                                value: params.auth.apiKey.matchLabels.value
                            }
                        ]
                    },
                    priority: 0,
                    when: [
                        {
                            operator: "eq",
                            selector: "auth.identity.metadata.labels." + params.auth.apiKey.matchLabels.name,
                            value: params.auth.apiKey.matchLabels.value
                        }
                    ]
                },
                jwt: {
                    metrics: false,
                    patternMatching: {
                        patterns: [
                            {
                                operator: "eq",
                                selector: "auth.identity.is_internal",
                                value: "true"
                            }
                        ]
                    },
                    priority: 10,
                    when: [
                        {
                            operator: "eq",
                            selector: "auth.identity.iss",
                            value: "https://sso.redhat.com/auth/realms/redhat-external"
                        }
                    ]
                }
            },
            hosts: [ params.auth.hostname ],
            response: {
                unauthorized: {
                    message: {
                        selector: "We were not able to match {auth.identity.email}"
                    }
                }
            }
        }
    }
}