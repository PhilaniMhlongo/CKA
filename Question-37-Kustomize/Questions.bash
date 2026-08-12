# Question: Kustomize Base + Overlay

# Task
# 1. Create a Kustomize structure at /tmp/exam/kustomize/ with:
#    - base/: an nginx deployment named nginx with 2 replicas
#    - overlays/production/: an overlay that
#        * sets replicas to 3
#        * adds label environment=production
#        * generates a ConfigMap named web-content from an index.html file
# 2. Apply the production overlay to namespace eda9e0ec987a-kustomize

# Documentation Reference
# Tasks -> Manage Kubernetes Objects -> Declarative Management using Kustomize
# https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
