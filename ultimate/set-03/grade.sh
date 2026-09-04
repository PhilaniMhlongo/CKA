#!/usr/bin/env bash
# Automatic marker — Ultimate CKA, Set 3
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "Ultimate CKA — Set 3" "$DIR"

# ---------------------------------------------------------------- Question 1
q 1 12 "ocean-tv-wl09 rollout and rollback"
exists "deployment ocean-tv-wl09 exists" deploy ocean-tv-wl09
expect "3 replicas" "3" get deploy ocean-tv-wl09 -o "jsonpath={.spec.replicas}"
expect "maxUnavailable 40%" "40%" \
  get deploy ocean-tv-wl09 -o "jsonpath={.spec.strategy.rollingUpdate.maxUnavailable}"
expect "maxSurge 55%" "55%" \
  get deploy ocean-tv-wl09 -o "jsonpath={.spec.strategy.rollingUpdate.maxSurge}"
shell "rolled back to the v1 image" \
  "kubectl get deploy ocean-tv-wl09 -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q ':v1'"
ready "deployment is fully ready" default ocean-tv-wl09
file_nonempty "/opt/revision-count.txt written" /opt/revision-count.txt
file_matches "revision count is a number" /opt/revision-count.txt "^[0-9]+$"

# ---------------------------------------------------------------- Question 2
q 2 6 "messaging pod and service"
exists "pod messaging-cka07-svcn exists" pod messaging-cka07-svcn -n msg-cka07
contains "image is redis:alpine" "redis:alpine" \
  get pod messaging-cka07-svcn -n msg-cka07 -o "jsonpath={.spec.containers[0].image}"
expect "label tier=msg" "msg" \
  get pod messaging-cka07-svcn -n msg-cka07 -o "jsonpath={.metadata.labels.tier}"
expect "service port 6379" "6379" \
  get svc messaging-service-cka07-svcn -n msg-cka07 -o "jsonpath={.spec.ports[0].port}"
endpoints_at_least "service has the pod as an endpoint" msg-cka07 messaging-service-cka07-svcn 1

# ---------------------------------------------------------------- Question 3
q 3 8 "hr-web-app NodePort service"
exists "deployment hr-web-app-cka08-svcn exists" deploy hr-web-app-cka08-svcn -n hr-cka08
expect "2 replicas" "2" get deploy hr-web-app-cka08-svcn -n hr-cka08 -o "jsonpath={.spec.replicas}"
expect "service type NodePort" "NodePort" \
  get svc hr-web-app-service-cka08-svcn -n hr-cka08 -o "jsonpath={.spec.type}"
expect "nodePort 30082" "30082" \
  get svc hr-web-app-service-cka08-svcn -n hr-cka08 -o "jsonpath={.spec.ports[0].nodePort}"
expect "targetPort 8080" "8080" \
  get svc hr-web-app-service-cka08-svcn -n hr-cka08 -o "jsonpath={.spec.ports[0].targetPort}"
endpoints_at_least "service has 2 endpoints" hr-cka08 hr-web-app-service-cka08-svcn 2

# ---------------------------------------------------------------- Question 4
q 4 10 "peach PVC bound and mounted"
exists "pvc peach-pvc-cka05-str exists" pvc peach-pvc-cka05-str
expect "requests 100Mi" "100Mi" \
  get pvc peach-pvc-cka05-str -o "jsonpath={.spec.resources.requests.storage}"
expect "access mode ReadWriteOnce" "ReadWriteOnce" \
  get pvc peach-pvc-cka05-str -o "jsonpath={.spec.accessModes[0]}"
expect "claim is Bound" "Bound" get pvc peach-pvc-cka05-str -o "jsonpath={.status.phase}"
expect "pod claims peach-pvc-cka05-str" "peach-pvc-cka05-str" \
  get pod peach-pod-cka05-str -o "jsonpath={.spec.volumes[0].persistentVolumeClaim.claimName}"
shell "mounted at /var/www/html" \
  "kubectl get pod peach-pod-cka05-str -o json | grep -q '\"mountPath\": *\"/var/www/html\"'"
pod_running "pod is Running" default peach-pod-cka05-str

# ---------------------------------------------------------------- Question 5
q 5 8 "nginx-wl06 resource units fixed"
pod_running "pod is Running" wl06-cka nginx-wl06
shell "memory request is in Mi, not Gi" \
  "kubectl get pod nginx-wl06 -n wl06-cka -o jsonpath='{.spec.containers[0].resources.requests.memory}' | grep -q 'Mi'"
shell "memory limit is in Mi, not Gi" \
  "kubectl get pod nginx-wl06 -n wl06-cka -o jsonpath='{.spec.containers[0].resources.limits.memory}' | grep -q 'Mi'"

# ---------------------------------------------------------------- Question 6
q 6 8 "app-wl03 deployed with limits unchanged"
exists "pod app-wl03 exists" pod app-wl03
pod_running "pod is Running" default app-wl03
expect "memory limit still 100Mi" "100Mi" \
  get pod app-wl03 -o "jsonpath={.spec.containers[0].resources.limits.memory}"
expect "cpu limit still 200m" "200m" \
  get pod app-wl03 -o "jsonpath={.spec.containers[0].resources.limits.cpu}"
shell "memory request no longer exceeds the limit" \
  "! kubectl get pod app-wl03 -o jsonpath='{.spec.containers[0].resources.requests.memory}' | grep -q 'Gi'"

# ---------------------------------------------------------------- Question 7
q 7 12 "red-probe pod stable"
exists "pod red-probe-cka12-trb exists" pod red-probe-cka12-trb -n trb-cka12
pod_running "pod is Running" trb-cka12 red-probe-cka12-trb
shell "args section was not changed" \
  "kubectl get pod red-probe-cka12-trb -n trb-cka12 -o jsonpath='{.spec.containers[0].args}' | grep -q 'sleep 3600'"
shell "probe no longer uses httpGet" \
  "! kubectl get pod red-probe-cka12-trb -n trb-cka12 -o jsonpath='{.spec.containers[0].livenessProbe}' | grep -q httpGet"
shell "pod is not restarting" \
  "test \"\$(kubectl get pod red-probe-cka12-trb -n trb-cka12 -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)\" -le 1"

# ---------------------------------------------------------------- Question 8
q 8 12 "db-deployment-cka05-trb ready"
ready "deployment has its replica ready" db-cka05-trb db-deployment-cka05-trb
shell "MYSQL_ROOT_PASSWORD still comes from the secret" \
  "kubectl get deploy db-deployment-cka05-trb -n db-cka05-trb -o json | tr -d ' \n' | grep -q '\"name\":\"MYSQL_ROOT_PASSWORD\"'"
shell "MYSQL_USER env var was kept" \
  "kubectl get deploy db-deployment-cka05-trb -n db-cka05-trb -o json | tr -d ' \n' | grep -q '\"name\":\"MYSQL_USER\"'"
shell "no reference to the non-existent DB_Passwd key remains" \
  "! kubectl get deploy db-deployment-cka05-trb -n db-cka05-trb -o json | grep -q 'DB_Passwd'"

# ---------------------------------------------------------------- Question 9
q 9 12 "blue-dp-cka09-trb running"
ready "deployment has its replica ready" blue-cka09-trb blue-dp-cka09-trb
shell "container command includes -c" \
  "kubectl get deploy blue-dp-cka09-trb -n blue-cka09-trb -o jsonpath='{.spec.template.spec.containers[0].command}' | grep -q '\\-c'"
shell "config mounted with a subPath" \
  "kubectl get deploy blue-dp-cka09-trb -n blue-cka09-trb -o json | grep -q 'subPath'"

# --------------------------------------------------------------- Question 10
q 10 12 "etcd snapshot taken and verified"
file_nonempty "/opt/cluster1_backup.db written" /opt/cluster1_backup.db
shell "snapshot file is a real etcd snapshot" \
  "ETCDCTL_API=3 etcdctl --write-out=table snapshot status /opt/cluster1_backup.db >/dev/null 2>&1 || etcdutl --write-out=table snapshot status /opt/cluster1_backup.db >/dev/null 2>&1"
file_nonempty "/opt/etcd-snapshot-status.txt written" /opt/etcd-snapshot-status.txt
file_matches "status output holds a hash/revision table" /opt/etcd-snapshot-status.txt "HASH|REVISION|TOTAL"

report
