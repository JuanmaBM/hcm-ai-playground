local resources = import 'resources.libsonnet';
local envoy = import 'envoy.libsonnet';
local authorino = import 'authorino.libsonnet';
local params = import 'params.libsonnet';

[
  resources.deployment(params),
  resources.service(params),
  envoy.configmap(params),
  envoy.deployment(params),
  envoy.service(params),
  envoy.route(params),
  authorino.instance(params),
  authorino.config(params),
]