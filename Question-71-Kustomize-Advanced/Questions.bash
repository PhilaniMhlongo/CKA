# Question: Advanced Kustomize (Cluster Architecture - harder than exam)

# Task
# Create a Kustomize structure at /tmp/exam/kustomize-adv/ with:
#
# base/:
#   - deployment 'api' (nginx:1.25, 1 replica, containerPort 80)
#   - service 'api-svc' (port 80 -> targetPort 80, selector app=api)
#
# overlays/production/ that:
#   - targets namespace d8f3b6a1c2e4-prod
#   - adds namePrefix prod-
#   - sets api replicas to 3
#   - adds a JSON6902 patch giving the api container a readinessProbe
#     (HTTP GET / on port 80)
#   - generates a Secret app-secret from literal API_KEY=abc123
#   - adds commonAnnotations owner: platform-team
#
# Apply the overlay. End state in d8f3b6a1c2e4-prod:
#   deployment prod-api (3 replicas, with readinessProbe, annotated),
#   service prod-api-svc, secret prod-app-secret-<hash>

# Documentation Reference
# Tasks -> Manage Kubernetes Objects -> Declarative Management using Kustomize
# https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
