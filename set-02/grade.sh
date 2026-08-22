#!/usr/bin/env bash
# Automatic marker — CKA Practice Exam Set 2
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "CKA Practice Exam — Set 2" "$DIR"

# ---------------------------------------------------------------- Question 1
q 1 6 "Pod resource-pod with requests and limits"
exists "namespace monitoring exists" ns monitoring
exists "pod resource-pod exists" pod resource-pod -n monitoring
expect "cpu request 100m" "100m" \
  get pod resource-pod -n monitoring -o "jsonpath={.spec.containers[0].resources.requests.cpu}"
expect "memory request 128Mi" "128Mi" \
  get pod resource-pod -n monitoring -o "jsonpath={.spec.containers[0].resources.requests.memory}"
expect "cpu limit 200m" "200m" \
  get pod resource-pod -n monitoring -o "jsonpath={.spec.containers[0].resources.limits.cpu}"
expect "memory limit 256Mi" "256Mi" \
  get pod resource-pod -n monitoring -o "jsonpath={.spec.containers[0].resources.limits.memory}"
expect "pod is Running" "Running" \
  get pod resource-pod -n monitoring -o "jsonpath={.status.phase}"

# ---------------------------------------------------------------- Question 2
q 2 8 "Pod health-check with liveness and readiness probes"
exists "namespace probes exists" ns probes
exists "pod health-check exists" pod health-check -n probes
expect "liveness httpGet path /" "/" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].livenessProbe.httpGet.path}"
expect "liveness port 80" "80" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].livenessProbe.httpGet.port}"
expect "liveness initialDelaySeconds 5" "5" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].livenessProbe.initialDelaySeconds}"
expect "readiness httpGet path /" "/" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].readinessProbe.httpGet.path}"
expect "readiness port 80" "80" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].readinessProbe.httpGet.port}"
expect "readiness initialDelaySeconds 5" "5" \
  get pod health-check -n probes -o "jsonpath={.spec.containers[0].readinessProbe.initialDelaySeconds}"
shell "pod is Ready" \
  "kubectl get pod health-check -n probes -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q True"

# ---------------------------------------------------------------- Question 3
q 3 8 "StorageClass fast-storage + PVC data-pvc"
expect "storageclass provisioner is kubernetes.io/no-provisioner" "kubernetes.io/no-provisioner" \
  get sc fast-storage -o "jsonpath={.provisioner}"
exists "namespace storage exists" ns storage
exists "pvc data-pvc exists" pvc data-pvc -n storage
expect "pvc uses storageclass fast-storage" "fast-storage" \
  get pvc data-pvc -n storage -o "jsonpath={.spec.storageClassName}"
expect "requests 1Gi" "1Gi" \
  get pvc data-pvc -n storage -o "jsonpath={.spec.resources.requests.storage}"
expect "access mode ReadWriteOnce" "ReadWriteOnce" \
  get pvc data-pvc -n storage -o "jsonpath={.spec.accessModes[0]}"
note "Pending is the expected phase for a no-provisioner claim."

# ---------------------------------------------------------------- Question 4
q 4 10 "Multi-container pod logger sharing an emptyDir"
exists "pod logger exists" pod logger -n monitoring
shell "pod has exactly 2 containers" \
  'C=$(kubectl get pod logger -n monitoring -o jsonpath="{.spec.containers[*].name}" | wc -w); [ "$C" = "2" ]'
contains "container named busybox present" "busybox" \
  get pod logger -n monitoring -o "jsonpath={.spec.containers[*].name}"
contains "container named fluentd present" "fluentd" \
  get pod logger -n monitoring -o "jsonpath={.spec.containers[*].name}"
contains "volume is an emptyDir" "emptyDir" \
  get pod logger -n monitoring -o "jsonpath={.spec.volumes}"
contains "first container mounts /var/log" "mountPath:/var/log" \
  get pod logger -n monitoring -o "jsonpath={.spec.containers[0].volumeMounts}"
contains "second container mounts /var/log" "mountPath:/var/log" \
  get pod logger -n monitoring -o "jsonpath={.spec.containers[1].volumeMounts}"
shell "/var/log/app.log is being written" \
  "kubectl exec logger -n monitoring -c busybox -- cat /var/log/app.log 2>/dev/null | grep -q ."

# ---------------------------------------------------------------- Question 5
q 5 12 "Taint + toleration-deploy + normal-deploy"
shell "a node carries taint special-workload=true:NoSchedule" \
  "kubectl get nodes -o jsonpath='{.items[*].spec.taints}' | grep -q special-workload"
exists "namespace scheduling exists" ns scheduling
expect "toleration-deploy has 2 replicas" "2" \
  get deploy toleration-deploy -n scheduling -o "jsonpath={.spec.replicas}"
contains "toleration key special-workload" "key:special-workload" \
  get deploy toleration-deploy -n scheduling -o "jsonpath={.spec.template.spec.tolerations}"
contains "toleration effect NoSchedule" "effect:NoSchedule" \
  get deploy toleration-deploy -n scheduling -o "jsonpath={.spec.template.spec.tolerations}"
expect "toleration-deploy has 2 available replicas" "2" \
  get deploy toleration-deploy -n scheduling -o "jsonpath={.status.availableReplicas}"
expect "normal-deploy has 2 replicas" "2" \
  get deploy normal-deploy -n scheduling -o "jsonpath={.spec.replicas}"
shell "normal-deploy has NO tolerations for special-workload" \
  "! kubectl get deploy normal-deploy -n scheduling -o jsonpath='{.spec.template.spec.tolerations}' | grep -q special-workload"
shell "no normal-deploy pod runs on the tainted node" \
  'T=$(kubectl get nodes -o jsonpath="{range .items[*]}{.metadata.name}{\"|\"}{.spec.taints}{\"\n\"}{end}" | grep special-workload | cut -d"|" -f1);
   [ -z "$T" ] && exit 1
   P=$(kubectl get pods -n scheduling -l app=normal-deploy -o jsonpath="{.items[*].spec.nodeName}")
   for n in $T; do echo "$P" | tr " " "\n" | grep -qx "$n" && exit 1; done; exit 0'

# ---------------------------------------------------------------- Question 6
q 6 10 "Pod Security Admission restricted + secure-pod"
expect "namespace enforces restricted" "restricted" \
  get ns security -o "jsonpath={.metadata.labels.podsecurity\.kubernetes\.io/enforce}"
exists "pod secure-pod was admitted" pod secure-pod -n security
expect "runAsNonRoot true" "true" \
  get pod secure-pod -n security -o "jsonpath={.spec.securityContext.runAsNonRoot}"
expect "runAsUser 1000" "1000" \
  get pod secure-pod -n security -o "jsonpath={.spec.securityContext.runAsUser}"
shell "seccompProfile RuntimeDefault (pod or container level)" \
  "kubectl get pod secure-pod -n security -o jsonpath='{.spec.securityContext.seccompProfile.type}{.spec.containers[0].securityContext.seccompProfile.type}' | grep -q RuntimeDefault"
expect "allowPrivilegeEscalation false" "false" \
  get pod secure-pod -n security -o "jsonpath={.spec.containers[0].securityContext.allowPrivilegeEscalation}"
expect "all capabilities dropped" "ALL" \
  get pod secure-pod -n security -o "jsonpath={.spec.containers[0].securityContext.capabilities.drop[0]}"

# ---------------------------------------------------------------- Question 7
q 7 12 "RBAC: app-admin ServiceAccount, Role, RoleBinding and pod"
exists "namespace cluster-admin exists" ns cluster-admin
exists "serviceaccount app-admin exists" sa app-admin -n cluster-admin
exists "role app-admin exists" role app-admin -n cluster-admin
expect "SA can watch pods" "yes" \
  auth can-i watch pods -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "SA can update deployments" "yes" \
  auth can-i update deployments.apps -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "SA can create configmaps" "yes" \
  auth can-i create configmaps -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "SA can delete configmaps" "yes" \
  auth can-i delete configmaps -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "SA CANNOT delete pods" "no" \
  auth can-i delete pods -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "SA CANNOT create deployments" "no" \
  auth can-i create deployments.apps -n cluster-admin --as=system:serviceaccount:cluster-admin:app-admin
expect "pod admin-pod uses the app-admin serviceaccount" "app-admin" \
  get pod admin-pod -n cluster-admin -o "jsonpath={.spec.serviceAccountName}"
expect "admin-pod is Running" "Running" \
  get pod admin-pod -n cluster-admin -o "jsonpath={.status.phase}"

# ---------------------------------------------------------------- Question 8
q 8 12 "Service discovery and DNS debugging"
exists "namespace dns-debug exists" ns dns-debug
expect "deployment web-app has 3 available replicas" "3" \
  get deploy web-app -n dns-debug -o "jsonpath={.status.availableReplicas}"
expect "service web-svc is ClusterIP" "ClusterIP" \
  get svc web-svc -n dns-debug -o "jsonpath={.spec.type}"
shell "service web-svc has endpoints" \
  "kubectl get endpoints web-svc -n dns-debug -o jsonpath='{.subsets[0].addresses[0].ip}' | grep -q ."
exists "pod dns-test exists" pod dns-test -n dns-debug
contains "dnsConfig search domain configured" "dns-debug.svc.cluster.local" \
  get pod dns-test -n dns-debug -o "jsonpath={.spec.dnsConfig.searches}"
shell "dns-test resolves web-svc (short name)" \
  "kubectl exec dns-test -n dns-debug -- nslookup web-svc 2>/dev/null | grep -q 'Address'"
shell "dns-test resolves web-svc.dns-debug.svc.cluster.local (FQDN)" \
  "kubectl exec dns-test -n dns-debug -- nslookup web-svc.dns-debug.svc.cluster.local 2>/dev/null | grep -q 'Address'"

# ---------------------------------------------------------------- Question 9
q 9 12 "Three-tier NetworkPolicy chain"
exists "namespace network exists" ns network
shell "deployments web, api and db all exist" \
  "kubectl get deploy web api db -n network >/dev/null 2>&1"
shell "pods carry labels app=web / app=api / app=db" \
  "kubectl get pods -n network -l app=web -o name | grep -q . && kubectl get pods -n network -l app=api -o name | grep -q . && kubectl get pods -n network -l app=db -o name | grep -q ."
expect "web-policy selects app=web" "web" \
  get netpol web-policy -n network -o "jsonpath={.spec.podSelector.matchLabels.app}"
expect "web-policy egress targets app=api" "api" \
  get netpol web-policy -n network -o "jsonpath={.spec.egress[0].to[0].podSelector.matchLabels.app}"
contains "web-policy declares Egress" "Egress" \
  get netpol web-policy -n network -o "jsonpath={.spec.policyTypes}"
expect "api-policy selects app=api" "api" \
  get netpol api-policy -n network -o "jsonpath={.spec.podSelector.matchLabels.app}"
expect "api-policy ingress from app=web" "web" \
  get netpol api-policy -n network -o "jsonpath={.spec.ingress[0].from[0].podSelector.matchLabels.app}"
expect "api-policy egress to app=db" "db" \
  get netpol api-policy -n network -o "jsonpath={.spec.egress[0].to[0].podSelector.matchLabels.app}"
expect "db-policy selects app=db" "db" \
  get netpol db-policy -n network -o "jsonpath={.spec.podSelector.matchLabels.app}"
expect "db-policy ingress from app=api" "api" \
  get netpol db-policy -n network -o "jsonpath={.spec.ingress[0].from[0].podSelector.matchLabels.app}"

# --------------------------------------------------------------- Question 10
q 10 10 "Rolling update, history capture and rollback"
exists "namespace upgrade exists" ns upgrade
expect "deployment has 4 replicas" "4" \
  get deploy app-v1 -n upgrade -o "jsonpath={.spec.replicas}"
expect "strategy type RollingUpdate" "RollingUpdate" \
  get deploy app-v1 -n upgrade -o "jsonpath={.spec.strategy.type}"
expect "maxUnavailable 1" "1" \
  get deploy app-v1 -n upgrade -o "jsonpath={.spec.strategy.rollingUpdate.maxUnavailable}"
expect "maxSurge 1" "1" \
  get deploy app-v1 -n upgrade -o "jsonpath={.spec.strategy.rollingUpdate.maxSurge}"
shell "rollout history saved to /tmp/exam/rollout-history.txt" \
  "[ -s /tmp/exam/rollout-history.txt ] && grep -qi revision /tmp/exam/rollout-history.txt"
shell "deployment went through at least 3 revisions (create, update, rollback)" \
  'R=$(kubectl get rs -n upgrade -l app=app-v1 --no-headers 2>/dev/null | wc -l); [ "${R:-0}" -ge 2 ]'
expect "image rolled back to nginx:1.19" "nginx:1.19" \
  get deploy app-v1 -n upgrade -o "jsonpath={.spec.template.spec.containers[0].image}"
expect "4 replicas available after rollback" "4" \
  get deploy app-v1 -n upgrade -o "jsonpath={.status.availableReplicas}"

report
