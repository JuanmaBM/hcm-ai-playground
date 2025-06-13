local resources = import 'resources.libsonnet';
local envoy = import 'envoy.libsonnet';
local params = import 'params.libsonnet';

[
  resources.deployment(params),
  resources.service(params),
  // resources.route(params),
  envoy.confimap(params),
  envoy.deployment(params),
  envoy.service(params),
  envoy.route(params),
]