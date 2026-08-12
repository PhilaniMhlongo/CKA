# Question: DNS Debugging (dnsConfig)

# Task
# 1. Create deployment web-app (3 replicas, nginx) in namespace
#    eda9e0ec987a-dns-debug
# 2. Create ClusterIP service web-svc targeting it on port 80
# 3. Create a debug pod dns-test (busybox, sleep 3600) with custom dnsConfig
#    adding search domain eda9e0ec987a-dns-debug.svc.cluster.local
# 4. From dns-test, verify it resolves web-svc and the FQDN

# Documentation Reference
# Concepts -> Services, Load Balancing, and Networking -> DNS for Services and Pods
# https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
