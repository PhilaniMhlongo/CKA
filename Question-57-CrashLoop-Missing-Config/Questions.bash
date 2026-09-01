# Question: Pod Stuck on Missing Configuration (Troubleshooting)
# DOMAIN: Troubleshooting

# In namespace d8f3b6a1c2e4-crashloop, the deployment config-app has been
# stuck for a while - its pod never reaches Running. The deployment
# manifest itself is CORRECT and must not be modified.

# Task
# 1. Diagnose why the pod cannot start (check both the init container and
#    the main container - there are TWO separate missing dependencies)
# 2. Create the missing resources so the pod starts on its own:
#    - the init container needs key db_host (any value, e.g. mysql.example.com)
#    - the main container needs credentials with keys DB_USER and DB_PASS
# 3. Wait until the deployment reports 1 ready replica

# Documentation Reference
# Concepts -> Configuration -> ConfigMaps / Secrets
# https://kubernetes.io/docs/concepts/configuration/configmap/
# https://kubernetes.io/docs/concepts/configuration/secret/
