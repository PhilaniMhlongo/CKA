#!/usr/bin/env bash
# Automatic marker — CKA Practice Exam Set 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "CKA Practice Exam — Set 1" "$DIR"

# ---------------------------------------------------------------- Question 1
q 1 5 "Pod nginx-pod in namespace app-team1"
exists "namespace app-team1 exists" ns app-team1
exists "pod nginx-pod exists" pod nginx-pod -n app-team1
expect "image is nginx:1.19" "nginx:1.19" \
  get pod nginx-pod -n app-team1 -o "jsonpath={.spec.containers[0].image}"
expect "label run=nginx-pod is set" "nginx-pod" \
  get pod nginx-pod -n app-team1 -o "jsonpath={.metadata.labels.run}"
expect "pod is Running" "Running" \
  get pod nginx-pod -n app-team1 -o "jsonpath={.status.phase}"

# ---------------------------------------------------------------- Question 2
q 2 8 "ConfigMap app-config mounted into config-pod"
exists "namespace config exists" ns config
expect "configmap key APP_COLOR=blue" "blue" \
  get cm app-config -n config -o "jsonpath={.data.APP_COLOR}"
exists "pod config-pod exists" pod config-pod -n config
expect "pod volume references configmap app-config" "app-config" \
  get pod config-pod -n config -o "jsonpath={.spec.volumes[0].configMap.name}"
contains "volume mounted at /etc/config" "mountPath:/etc/config" \
  get pod config-pod -n config -o "jsonpath={.spec.containers[0].volumeMounts}"
shell "/etc/config/APP_COLOR reads 'blue' inside the container" \
  "kubectl exec config-pod -n config -- cat /etc/config/APP_COLOR 2>/dev/null | grep -qx blue"

# ---------------------------------------------------------------- Question 3
q 3 10 "PVC data-pvc consumed by data-pod"
exists "namespace storage-task exists" ns storage-task
exists "pvc data-pvc exists" pvc data-pvc -n storage-task
expect "storageClassName is standard" "standard" \
  get pvc data-pvc -n storage-task -o "jsonpath={.spec.storageClassName}"
expect "requests 2Gi" "2Gi" \
  get pvc data-pvc -n storage-task -o "jsonpath={.spec.resources.requests.storage}"
expect "access mode ReadWriteOnce" "ReadWriteOnce" \
  get pvc data-pvc -n storage-task -o "jsonpath={.spec.accessModes[0]}"
exists "pod data-pod exists" pod data-pod -n storage-task
expect "pod claims data-pvc" "data-pvc" \
  get pod data-pod -n storage-task -o "jsonpath={.spec.volumes[0].persistentVolumeClaim.claimName}"
contains "mounted at /usr/share/nginx/html" "mountPath:/usr/share/nginx/html" \
  get pod data-pod -n storage-task -o "jsonpath={.spec.containers[0].volumeMounts}"
note "PVC Pending is fine here — binding is not marked."

# ---------------------------------------------------------------- Question 4
q 4 10 "Deployment web-app + NodePort service web-service"
exists "namespace web exists" ns web
expect "deployment has 3 replicas" "3" \
  get deploy web-app -n web -o "jsonpath={.spec.replicas}"
expect "image is nginx:1.19" "nginx:1.19" \
  get deploy web-app -n web -o "jsonpath={.spec.template.spec.containers[0].image}"
expect "3 replicas available" "3" \
  get deploy web-app -n web -o "jsonpath={.status.availableReplicas}"
expect "service type is NodePort" "NodePort" \
  get svc web-service -n web -o "jsonpath={.spec.type}"
expect "service port is 80" "80" \
  get svc web-service -n web -o "jsonpath={.spec.ports[0].port}"
shell "service has endpoints (selector matches pods)" \
  "kubectl get endpoints web-service -n web -o jsonpath='{.subsets[0].addresses[0].ip}' | grep -q ."

# ---------------------------------------------------------------- Question 5
q 5 10 "NetworkPolicy db-policy"
exists "namespace networking exists" ns networking
exists "networkpolicy db-policy exists" netpol db-policy -n networking
expect "podSelector targets role=db" "db" \
  get netpol db-policy -n networking -o "jsonpath={.spec.podSelector.matchLabels.role}"
expect "policyTypes contains Ingress" "Ingress" \
  get netpol db-policy -n networking -o "jsonpath={.spec.policyTypes[0]}"
expect "ingress allowed from role=frontend" "frontend" \
  get netpol db-policy -n networking -o "jsonpath={.spec.ingress[0].from[0].podSelector.matchLabels.role}"
expect "restricted to port 3306" "3306" \
  get netpol db-policy -n networking -o "jsonpath={.spec.ingress[0].ports[0].port}"
expect "protocol is TCP" "TCP" \
  get netpol db-policy -n networking -o "jsonpath={.spec.ingress[0].ports[0].protocol}"

# ---------------------------------------------------------------- Question 6
q 6 10 "ServiceAccount app-sa with Role pod-reader"
exists "namespace rbac exists" ns rbac
exists "serviceaccount app-sa exists" sa app-sa -n rbac
exists "role pod-reader exists" role pod-reader -n rbac
contains "role allows get on pods" "get" \
  get role pod-reader -n rbac -o "jsonpath={.rules[0].verbs}"
contains "role allows list on pods" "list" \
  get role pod-reader -n rbac -o "jsonpath={.rules[0].verbs}"
expect "rolebinding read-pods targets role pod-reader" "pod-reader" \
  get rolebinding read-pods -n rbac -o "jsonpath={.roleRef.name}"
expect "rolebinding subject is serviceaccount app-sa" "app-sa" \
  get rolebinding read-pods -n rbac -o "jsonpath={.subjects[0].name}"
expect "app-sa CAN list pods" "yes" \
  auth can-i list pods -n rbac --as=system:serviceaccount:rbac:app-sa
expect "app-sa CANNOT delete pods" "no" \
  auth can-i delete pods -n rbac --as=system:serviceaccount:rbac:app-sa

# ---------------------------------------------------------------- Question 7
q 7 12 "Deployment scaling-app with resources + HPA"
exists "namespace scaling exists" ns scaling
expect "deployment has 2 replicas" "2" \
  get deploy scaling-app -n scaling -o "jsonpath={.spec.replicas}"
expect "cpu request 200m" "200m" \
  get deploy scaling-app -n scaling -o "jsonpath={.spec.template.spec.containers[0].resources.requests.cpu}"
expect "memory request 256Mi" "256Mi" \
  get deploy scaling-app -n scaling -o "jsonpath={.spec.template.spec.containers[0].resources.requests.memory}"
expect "cpu limit 500m" "500m" \
  get deploy scaling-app -n scaling -o "jsonpath={.spec.template.spec.containers[0].resources.limits.cpu}"
expect "memory limit 512Mi" "512Mi" \
  get deploy scaling-app -n scaling -o "jsonpath={.spec.template.spec.containers[0].resources.limits.memory}"
expect "hpa scales deployment scaling-app" "scaling-app" \
  get hpa scaling-app -n scaling -o "jsonpath={.spec.scaleTargetRef.name}"
expect "hpa minReplicas is 2" "2" \
  get hpa scaling-app -n scaling -o "jsonpath={.spec.minReplicas}"
expect "hpa maxReplicas is 5" "5" \
  get hpa scaling-app -n scaling -o "jsonpath={.spec.maxReplicas}"
shell "hpa targets 70% CPU" \
  "kubectl get hpa scaling-app -n scaling -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}{.spec.targetCPUUtilizationPercentage}' | grep -qx 70"

# ---------------------------------------------------------------- Question 8
q 8 12 "Node label disk=ssd + node affinity deployment"
shell "at least one node labelled disk=ssd" \
  "kubectl get nodes -l disk=ssd -o name | grep -q ."
exists "namespace scheduling exists" ns scheduling
expect "deployment has 3 replicas" "3" \
  get deploy app-scheduling -n scheduling -o "jsonpath={.spec.replicas}"
shell "uses requiredDuringSchedulingIgnoredDuringExecution" \
  "kubectl get deploy app-scheduling -n scheduling -o jsonpath='{.spec.template.spec.affinity.nodeAffinity}' | grep -q requiredDuringScheduling"
contains "affinity matches key disk" "disk" \
  get deploy app-scheduling -n scheduling -o "jsonpath={.spec.template.spec.affinity.nodeAffinity}"
contains "affinity matches value ssd" "ssd" \
  get deploy app-scheduling -n scheduling -o "jsonpath={.spec.template.spec.affinity.nodeAffinity}"
expect "3 replicas available" "3" \
  get deploy app-scheduling -n scheduling -o "jsonpath={.status.availableReplicas}"

# ---------------------------------------------------------------- Question 9
q 9 12 "DaemonSet log-collector"
exists "namespace logging exists" ns logging
exists "daemonset log-collector exists" ds log-collector -n logging
expect "image busybox:1.36" "busybox:1.36" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.containers[0].image}"
contains "container runs the logging loop" "collecting logs from" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.containers[0].command}"
contains "hostPath /var/log" "path:/var/log" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.volumes}"
contains "volume named host-logs" "name:host-logs" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.volumes}"
contains "mounted at /host-logs" "mountPath:/host-logs" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.containers[0].volumeMounts}"
contains "mount is readOnly" "readOnly:true" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.containers[0].volumeMounts}"
contains "tolerates all taints (operator: Exists)" "operator:Exists" \
  get ds log-collector -n logging -o "jsonpath={.spec.template.spec.tolerations}"
shell "scheduled onto every node in the cluster" \
  'D=$(kubectl get ds log-collector -n logging -o jsonpath="{.status.desiredNumberScheduled}"); N=$(kubectl get nodes --no-headers | wc -l); [ -n "$D" ] && [ "$D" = "$N" ]'
shell "all daemonset pods are ready" \
  'D=$(kubectl get ds log-collector -n logging -o jsonpath="{.status.desiredNumberScheduled}"); R=$(kubectl get ds log-collector -n logging -o jsonpath="{.status.numberReady}"); [ -n "$D" ] && [ "$D" = "$R" ]'

# --------------------------------------------------------------- Question 10
q 10 11 "Troubleshoot deployment failing-app"
exists "deployment failing-app still exists" deploy failing-app -n troubleshoot
expect "containerPort corrected to 80" "80" \
  get deploy failing-app -n troubleshoot -o "jsonpath={.spec.template.spec.containers[0].ports[0].containerPort}"
expect "memory limit raised to 256Mi" "256Mi" \
  get deploy failing-app -n troubleshoot -o "jsonpath={.spec.template.spec.containers[0].resources.limits.memory}"
expect "liveness probe targets port 80" "80" \
  get deploy failing-app -n troubleshoot -o "jsonpath={.spec.template.spec.containers[0].livenessProbe.httpGet.port}"
expect "2 replicas available" "2" \
  get deploy failing-app -n troubleshoot -o "jsonpath={.status.availableReplicas}"
shell "no container restarts in the last generation" \
  'R=$(kubectl get pods -n troubleshoot -l app=failing-app -o jsonpath="{.items[*].status.containerStatuses[0].restartCount}" | tr " " "+" | sed "s/+$//"); [ -z "$R" ] && exit 1; [ "$(( R ))" -le 2 ]'

report
