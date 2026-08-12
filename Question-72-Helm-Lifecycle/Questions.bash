# Question: Helm Release Lifecycle (Cluster Architecture - harder than exam)

# Task
# 1. Add the Bitnami repo (https://charts.bitnami.com/bitnami) and update it
# 2. Install the nginx chart as release web-lifecycle in namespace
#    d8f3b6a1c2e4-helm-lab with replicaCount=1
# 3. Upgrade the release to replicaCount=3 (revision 2)
# 4. The upgrade is then deemed faulty: roll the release back to revision 1
# 5. End state:
#    - helm history shows at least 3 revisions (install, upgrade, rollback)
#    - the release status is 'deployed'
#    - the deployment is back to 1 replica

# Documentation Reference
# Helm Docs -> helm upgrade / helm rollback / helm history
# https://helm.sh/docs/helm/helm_rollback/
