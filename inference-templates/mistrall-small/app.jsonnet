local resources = import 'resources.libsonnet';
local params = import 'params.libsonnet';

[
  resources.deployment(params),
  resources.service(params),
  resources.route(params),
]