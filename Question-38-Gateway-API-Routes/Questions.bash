# Question: Gateway API

# Task
# 1. In namespace eda9e0ec987a-gateway, create deployments app1 and app2
#    (1 replica each, nginx) with services app1-svc and app2-svc exposing
#    port 8080 (targetPort 80)
# 2. Create a Gateway main-gateway with an HTTP listener on port 80
#    (use the GatewayClass available in the cluster - check
#    kubectl get gatewayclass)
# 3. Create an HTTPRoute app-routes attached to main-gateway routing:
#    - /app1 -> app1-svc:8080
#    - /app2 -> app2-svc:8080

# Documentation Reference
# Concepts -> Services, Load Balancing, and Networking -> Gateway API
# https://kubernetes.io/docs/concepts/services-networking/gateway/
