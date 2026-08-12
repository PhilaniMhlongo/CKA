# Question: Tiered NetworkPolicies (web -> api -> db)

# Task
# 1. Create deployments web, api and db (1 replica each, nginx) in namespace
#    eda9e0ec987a-network, each labelled app=<name>
# 2. Create three NetworkPolicies:
#    - web-policy: web egress only to api
#    - api-policy: api ingress from web, egress to db
#    - db-policy:  db ingress only from api

# Documentation Reference
# Concepts -> Services, Load Balancing, and Networking -> Network Policies
# https://kubernetes.io/docs/concepts/services-networking/network-policies/
