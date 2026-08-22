#!/usr/bin/env bash
# Automatic marker — CKA Practice Exam Set 3 (Advanced)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "CKA Practice Exam — Set 3 (Advanced)" "$DIR"

# ---------------------------------------------------------------- Question 1
q 1 7 "Default StorageClass fast-local"
exists "storageclass fast-local exists" sc fast-local
expect "provisioner rancher.io/local-path" "rancher.io/local-path" \
  get sc fast-local -o "jsonpath={.provisioner}"
expect "volumeBindingMode WaitForFirstConsumer" "WaitForFirstConsumer" \
  get sc fast-local -o "jsonpath={.volumeBindingMode}"
contains "marked as default class" "is-default-class:true" \
  get sc fast-local -o "jsonpath={.metadata.annotations}"

# ---------------------------------------------------------------- Question 2
q 2 10 "Static PV manual-pv bound to manual-pvc and mounted"
exists "persistentvolume manual-pv exists" pv manual-pv
expect "capacity 1Gi" "1Gi" \
  get pv manual-pv -o "jsonpath={.spec.capacity.storage}"
expect "access mode ReadWriteOnce" "ReadWriteOnce" \
  get pv manual-pv -o "jsonpath={.spec.accessModes[0]}"
expect "hostPath /mnt/data" "/mnt/data" \
  get pv manual-pv -o "jsonpath={.spec.hostPath.path}"
contains "nodeAffinity pins to kubernetes.io/hostname" "kubernetes.io/hostname" \
  get pv manual-pv -o "jsonpath={.spec.nodeAffinity}"
exists "namespace manual-storage exists" ns manual-storage
exists "pvc manual-pvc exists" pvc manual-pvc -n manual-storage
expect "pvc storageClassName is empty string" "" \
  get pvc manual-pvc -n manual-storage -o "jsonpath={.spec.storageClassName}"
expect "pvc is Bound" "Bound" \
  get pvc manual-pvc -n manual-storage -o "jsonpath={.status.phase}"
contains "manual-pod mounts the pvc at /data" "mountPath:/data" \
  get pod manual-pod -n manual-storage -o "jsonpath={.spec.containers[0].volumeMounts}"
expect "manual-pod is Running" "Running" \
  get pod manual-pod -n manual-storage -o "jsonpath={.status.phase}"

# ---------------------------------------------------------------- Question 3
q 3 10 "Headless service + StatefulSet web"
expect "storageclass cold provisioner" "rancher.io/local-path" \
  get sc cold -o "jsonpath={.provisioner}"
exists "namespace stateful exists" ns stateful
expect "service web-svc is headless (clusterIP None)" "None" \
  get svc web-svc -n stateful -o "jsonpath={.spec.clusterIP}"
expect "service selector app=web" "web" \
  get svc web-svc -n stateful -o "jsonpath={.spec.selector.app}"
expect "statefulset has 3 replicas" "3" \
  get sts web -n stateful -o "jsonpath={.spec.replicas}"
expect "serviceName is web-svc" "web-svc" \
  get sts web -n stateful -o "jsonpath={.spec.serviceName}"
expect "volumeClaimTemplate named www" "www" \
  get sts web -n stateful -o "jsonpath={.spec.volumeClaimTemplates[0].metadata.name}"
expect "template uses storageclass cold" "cold" \
  get sts web -n stateful -o "jsonpath={.spec.volumeClaimTemplates[0].spec.storageClassName}"
expect "template requests 1Gi" "1Gi" \
  get sts web -n stateful -o "jsonpath={.spec.volumeClaimTemplates[0].spec.resources.requests.storage}"
contains "www mounted at /usr/share/nginx/html" "mountPath:/usr/share/nginx/html" \
  get sts web -n stateful -o "jsonpath={.spec.template.spec.containers[0].volumeMounts}"

# ---------------------------------------------------------------- Question 4
q 4 10 "LimitRange, ResourceQuota and inheriting deployment"
exists "namespace limits exists" ns limits
expect "limitrange default cpu limit 200m" "200m" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].default.cpu}"
expect "limitrange default memory limit 256Mi" "256Mi" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].default.memory}"
expect "limitrange default cpu request 100m" "100m" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].defaultRequest.cpu}"
expect "limitrange default memory request 128Mi" "128Mi" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].defaultRequest.memory}"
expect "limitrange max cpu 500m" "500m" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].max.cpu}"
expect "limitrange max memory 512Mi" "512Mi" \
  get limitrange resource-limits -n limits -o "jsonpath={.spec.limits[0].max.memory}"
expect "quota hard cpu 2" "2" \
  get quota compute-quota -n limits -o "jsonpath={.spec.hard.cpu}"
expect "quota hard memory 2Gi" "2Gi" \
  get quota compute-quota -n limits -o "jsonpath={.spec.hard.memory}"
expect "quota hard pods 5" "5" \
  get quota compute-quota -n limits -o "jsonpath={.spec.hard.pods}"
expect "test-limits has 2 available replicas" "2" \
  get deploy test-limits -n limits -o "jsonpath={.status.availableReplicas}"
shell "test-limits pods inherited the default cpu request 100m" \
  "kubectl get pods -n limits -l app=test-limits -o jsonpath='{.items[0].spec.containers[0].resources.requests.cpu}' | grep -qx 100m"

# ---------------------------------------------------------------- Question 5
q 5 8 "resource-consumer deployment with HPA"
exists "namespace consumer exists" ns consumer
expect "deployment has 3 replicas" "3" \
  get deploy resource-consumer -n consumer -o "jsonpath={.spec.replicas}"
contains "uses the resource-consumer image" "resource-consumer" \
  get deploy resource-consumer -n consumer -o "jsonpath={.spec.template.spec.containers[0].image}"
expect "cpu request 100m" "100m" \
  get deploy resource-consumer -n consumer -o "jsonpath={.spec.template.spec.containers[0].resources.requests.cpu}"
expect "memory limit 256Mi" "256Mi" \
  get deploy resource-consumer -n consumer -o "jsonpath={.spec.template.spec.containers[0].resources.limits.memory}"
expect "hpa minReplicas 3" "3" \
  get hpa resource-consumer -n consumer -o "jsonpath={.spec.minReplicas}"
expect "hpa maxReplicas 6" "6" \
  get hpa resource-consumer -n consumer -o "jsonpath={.spec.maxReplicas}"
shell "hpa targets 50% CPU" \
  "kubectl get hpa resource-consumer -n consumer -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}{.spec.targetCPUUtilizationPercentage}' | grep -qx 50"

# ---------------------------------------------------------------- Question 6
q 6 10 "PriorityClasses and pod anti-affinity"
expect "high-priority value is 1000" "1000" \
  get priorityclass high-priority -o "jsonpath={.value}"
expect "low-priority value is 100" "100" \
  get priorityclass low-priority -o "jsonpath={.value}"
expect "high-priority globalDefault false" "false" \
  get priorityclass high-priority -o "jsonpath={.globalDefault}"
expect "high-priority preemptionPolicy PreemptLowerPriority" "PreemptLowerPriority" \
  get priorityclass high-priority -o "jsonpath={.preemptionPolicy}"
exists "namespace priority exists" ns priority
expect "high-priority-pod uses priorityClassName high-priority" "high-priority" \
  get pod high-priority-pod -n priority -o "jsonpath={.spec.priorityClassName}"
expect "low-priority-pod uses priorityClassName low-priority" "low-priority" \
  get pod low-priority-pod -n priority -o "jsonpath={.spec.priorityClassName}"
contains "high-priority-pod has required podAntiAffinity" "topologyKey:kubernetes.io/hostname" \
  get pod high-priority-pod -n priority -o "jsonpath={.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution}"
contains "low-priority-pod has required podAntiAffinity" "topologyKey:kubernetes.io/hostname" \
  get pod low-priority-pod -n priority -o "jsonpath={.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution}"
shell "anti-affinity selectors reference the opposite pod's label" \
  "kubectl get pod high-priority-pod -n priority -o jsonpath='{.spec.affinity.podAntiAffinity}' | grep -q low && kubectl get pod low-priority-pod -n priority -o jsonpath='{.spec.affinity.podAntiAffinity}' | grep -q high"

# ---------------------------------------------------------------- Question 7
q 7 8 "DNS tester pod writing results to a file"
exists "namespace dns-config exists" ns dns-config
expect "dns-app has 2 available replicas" "2" \
  get deploy dns-app -n dns-config -o "jsonpath={.status.availableReplicas}"
expect "service dns-svc is ClusterIP" "ClusterIP" \
  get svc dns-svc -n dns-config -o "jsonpath={.spec.type}"
contains "dns-tester uses the dnstools image" "dnstools" \
  get pod dns-tester -n dns-config -o "jsonpath={.spec.containers[0].image}"
shell "/tmp/dns-test.txt exists inside dns-tester" \
  "kubectl exec dns-tester -n dns-config -- cat /tmp/dns-test.txt 2>/dev/null | grep -q ."
shell "file contains a lookup of the short name dns-svc" \
  "kubectl exec dns-tester -n dns-config -- cat /tmp/dns-test.txt 2>/dev/null | grep -q 'dns-svc'"
shell "file contains a lookup of the FQDN" \
  "kubectl exec dns-tester -n dns-config -- cat /tmp/dns-test.txt 2>/dev/null | grep -q 'dns-svc.dns-config.svc.cluster.local'"

# ---------------------------------------------------------------- Question 8
q 8 12 "Kustomize base and production overlay"
shell "base/kustomization.yaml exists" "[ -s /tmp/exam/kustomize/base/kustomization.yaml ]"
shell "base contains a deployment manifest" \
  "grep -rql 'kind: Deployment' /tmp/exam/kustomize/base/"
shell "production overlay kustomization exists" \
  "[ -s /tmp/exam/kustomize/overlays/production/kustomization.yaml ]"
shell "overlay references the base" \
  "grep -q '\.\./\.\./base' /tmp/exam/kustomize/overlays/production/kustomization.yaml"
shell "overlay declares an index.html file for the configmap generator" \
  "[ -s /tmp/exam/kustomize/overlays/production/index.html ]"
shell "overlay builds cleanly with kubectl kustomize" \
  "kubectl kustomize /tmp/exam/kustomize/overlays/production/ >/dev/null"
exists "namespace kustomize exists" ns kustomize
expect "deployment nginx has 3 replicas" "3" \
  get deploy nginx -n kustomize -o "jsonpath={.spec.replicas}"
expect "deployment carries label environment=production" "production" \
  get deploy nginx -n kustomize -o "jsonpath={.metadata.labels.environment}"
shell "generated configmap web-content-<hash> exists" \
  "kubectl get cm -n kustomize -o name | grep -q web-content"
expect "deployment is available" "3" \
  get deploy nginx -n kustomize -o "jsonpath={.status.availableReplicas}"

# ---------------------------------------------------------------- Question 9
q 9 10 "Helm release web-release"
shell "helm binary available" "command -v helm"
shell "bitnami repo is registered" "helm repo list 2>/dev/null | grep -q charts.bitnami.com"
shell "release web-release exists in namespace helm-test" \
  "helm status web-release -n helm-test >/dev/null 2>&1"
shell "release is in deployed status" \
  "helm list -n helm-test 2>/dev/null | grep web-release | grep -q deployed"
shell "value service.type=NodePort was supplied" \
  "helm get values web-release -n helm-test 2>/dev/null | grep -q NodePort"
shell "value replicaCount=2 was supplied" \
  "helm get values web-release -n helm-test 2>/dev/null | grep -qE 'replicaCount:[[:space:]]*2'"
note "Chart pods may be ImagePullBackOff — not marked."

# --------------------------------------------------------------- Question 10
q 10 15 "Gateway API: Gateway + HTTPRoute fanout"
shell "Gateway API CRDs installed" \
  "kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1"
shell "HTTPRoute CRD installed" \
  "kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1"
exists "namespace gateway exists" ns gateway
expect "app1 deployment is available" "1" \
  get deploy app1 -n gateway -o "jsonpath={.status.availableReplicas}"
expect "app2 deployment is available" "1" \
  get deploy app2 -n gateway -o "jsonpath={.status.availableReplicas}"
expect "app1-svc exposes port 8080" "8080" \
  get svc app1-svc -n gateway -o "jsonpath={.spec.ports[0].port}"
expect "app1-svc targets container port 80" "80" \
  get svc app1-svc -n gateway -o "jsonpath={.spec.ports[0].targetPort}"
expect "app2-svc exposes port 8080" "8080" \
  get svc app2-svc -n gateway -o "jsonpath={.spec.ports[0].port}"
exists "gateway main-gateway exists" gateway main-gateway -n gateway
expect "listener protocol HTTP" "HTTP" \
  get gateway main-gateway -n gateway -o "jsonpath={.spec.listeners[0].protocol}"
expect "listener port 80" "80" \
  get gateway main-gateway -n gateway -o "jsonpath={.spec.listeners[0].port}"
exists "httproute app-routes exists" httproute app-routes -n gateway
expect "httproute attaches to main-gateway" "main-gateway" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.parentRefs[0].name}"
contains "rule for path /app1" "/app1" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.rules}"
contains "rule for path /app2" "/app2" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.rules}"
expect "/app1 backend is app1-svc" "app1-svc" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.rules[0].backendRefs[0].name}"
expect "/app1 backend port 8080" "8080" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.rules[0].backendRefs[0].port}"
expect "/app2 backend is app2-svc" "app2-svc" \
  get httproute app-routes -n gateway -o "jsonpath={.spec.rules[1].backendRefs[0].name}"

report
