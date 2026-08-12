# Question: NetworkPolicy Connectivity Debug (Troubleshooting - harder than exam)

# In namespace d8f3b6a1c2e4-netpol-debug, the pod 'client' (label app=client)
# must be able to reach the deployment 'web' (label app=web) through the
# service web-svc on port 80 - but every request fails.
# A security team requires that the existing 'default-deny-all'
# NetworkPolicy stays in place.

# Task
# 1. Find and fix the service misconfiguration
# 2. WITHOUT deleting default-deny-all, add NetworkPolicies so that:
#    - web accepts ingress from client on TCP 80
#    - client is allowed egress to web on TCP 80 AND egress to
#      cluster DNS on port 53 (UDP and TCP) - otherwise name resolution
#      of web-svc stays broken
# 3. Prove it: kubectl exec client -- curl -s --max-time 5 http://web-svc

# Documentation Reference
# Concepts -> Services, Load Balancing, and Networking -> Network Policies
# https://kubernetes.io/docs/concepts/services-networking/network-policies/
