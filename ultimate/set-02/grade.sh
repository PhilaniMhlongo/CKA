#!/usr/bin/env bash
# Automatic marker — Ultimate CKA, Set 2
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "Ultimate CKA — Set 2" "$DIR"
SA2="system:serviceaccount:default:deploy-cka20-arch"
SA7="system:serviceaccount:trb-cka24:thor-cka24-trb"

# ---------------------------------------------------------------- Question 1
q 1 10 "ServiceAccount + ClusterRole + binding"
exists "serviceaccount deploy-cka20-arch exists" sa deploy-cka20-arch
exists "clusterrole deploy-role-cka20-arch exists" clusterrole deploy-role-cka20-arch
exists "clusterrolebinding deploy-role-binding-cka20-arch exists" clusterrolebinding deploy-role-binding-cka20-arch
shell "role targets the apps/deployments resource" \
  "kubectl get clusterrole deploy-role-cka20-arch -o jsonpath='{.rules[*].resources}' | grep -q deployments"
shell "SA can get deployments" "kubectl auth can-i get deployments --as=$SA2 -n default | grep -qx yes"
shell "SA canNOT delete deployments" "kubectl auth can-i delete deployments --as=$SA2 -n default | grep -qx no"

# ---------------------------------------------------------------- Question 2
q 2 8 "Secret from file"
exists "secret db-user-pass-cka17-arch exists" secret db-user-pass-cka17-arch
shell "secret carries the file contents" \
  "kubectl get secret db-user-pass-cka17-arch -o jsonpath='{.data}' | base64 -d 2>/dev/null | grep -q . || kubectl get secret db-user-pass-cka17-arch -o json | grep -q 'db-user-pass'"
shell "a value decodes to the password from the file" \
  "kubectl get secret db-user-pass-cka17-arch -o json | python3 -c 'import sys,json,base64; d=json.load(sys.stdin)[\"data\"]; print(any(\"Str0ngP4ss\" in base64.b64decode(v).decode(errors=\"ignore\") for v in d.values()))' | grep -q True"

# ---------------------------------------------------------------- Question 3
q 3 8 "PVC apple-pvc-cka04-str bound"
exists "pvc apple-pvc-cka04-str exists" pvc apple-pvc-cka04-str
expect "requests 40Mi" "40Mi" \
  get pvc apple-pvc-cka04-str -o "jsonpath={.spec.resources.requests.storage}"
expect "access mode ReadWriteOnce" "ReadWriteOnce" \
  get pvc apple-pvc-cka04-str -o "jsonpath={.spec.accessModes[0]}"
expect "storage class manual" "manual" \
  get pvc apple-pvc-cka04-str -o "jsonpath={.spec.storageClassName}"
expect "claim is Bound" "Bound" get pvc apple-pvc-cka04-str -o "jsonpath={.status.phase}"

# ---------------------------------------------------------------- Question 4
q 4 8 "StorageClass banana-sc-cka08-str"
exists "storageclass exists" sc banana-sc-cka08-str
expect "provisioner is no-provisioner" "kubernetes.io/no-provisioner" \
  get sc banana-sc-cka08-str -o "jsonpath={.provisioner}"
expect "binding mode WaitForFirstConsumer" "WaitForFirstConsumer" \
  get sc banana-sc-cka08-str -o "jsonpath={.volumeBindingMode}"
expect "volume expansion enabled" "true" \
  get sc banana-sc-cka08-str -o "jsonpath={.allowVolumeExpansion}"

# ---------------------------------------------------------------- Question 5
q 5 12 "Service across two pods, and pod IPs to file"
exists "service service-3421-svcn exists" svc service-3421-svcn -n svcn-cka05
expect "type is ClusterIP" "ClusterIP" \
  get svc service-3421-svcn -n svcn-cka05 -o "jsonpath={.spec.type}"
expect "port 8080" "8080" get svc service-3421-svcn -n svcn-cka05 -o "jsonpath={.spec.ports[0].port}"
expect "targetPort 80" "80" get svc service-3421-svcn -n svcn-cka05 -o "jsonpath={.spec.ports[0].targetPort}"
endpoints_at_least "service has exactly the 2 pods as endpoints" svcn-cka05 service-3421-svcn 2
shell "service does NOT also select the decoy pod-99" \
  "test \$(kubectl get endpoints service-3421-svcn -n svcn-cka05 -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w) -eq 2"
file_nonempty "/root/pod_ips_cka05_svcn written" /root/pod_ips_cka05_svcn
file_has "file has the POD_NAME heading" /root/pod_ips_cka05_svcn "POD_NAME"
file_has "file lists pod-23" /root/pod_ips_cka05_svcn "pod-23"

# ---------------------------------------------------------------- Question 6
q 6 10 "Ingress nginx-ingress-cka04-svcn"
exists "ingress exists" ingress nginx-ingress-cka04-svcn -n svcn-cka04
expect "pathType is Prefix" "Prefix" \
  get ingress nginx-ingress-cka04-svcn -n svcn-cka04 -o "jsonpath={.spec.rules[0].http.paths[0].pathType}"
expect "path is /" "/" \
  get ingress nginx-ingress-cka04-svcn -n svcn-cka04 -o "jsonpath={.spec.rules[0].http.paths[0].path}"
expect "backend service is nginx-service-cka04-svcn" "nginx-service-cka04-svcn" \
  get ingress nginx-ingress-cka04-svcn -n svcn-cka04 -o "jsonpath={.spec.rules[0].http.paths[0].backend.service.name}"
expect "backend port 80" "80" \
  get ingress nginx-ingress-cka04-svcn -n svcn-cka04 -o "jsonpath={.spec.rules[0].http.paths[0].backend.service.port.number}"
expect "ssl-redirect annotation is false" "false" \
  get ingress nginx-ingress-cka04-svcn -n svcn-cka04 \
  -o "jsonpath={.metadata.annotations.nginx\.ingress\.kubernetes\.io/ssl-redirect}"

# ---------------------------------------------------------------- Question 7
q 7 12 "RBAC repaired for thor-cka24-trb"
shell "can list pods in trb-cka24" "kubectl auth can-i list pods --as=$SA7 -n trb-cka24 | grep -qx yes"
shell "can get pods in trb-cka24" "kubectl auth can-i get pods --as=$SA7 -n trb-cka24 | grep -qx yes"
shell "can list secrets in trb-cka24" "kubectl auth can-i list secrets --as=$SA7 -n trb-cka24 | grep -qx yes"
shell "can get secrets in trb-cka24" "kubectl auth can-i get secrets --as=$SA7 -n trb-cka24 | grep -qx yes"
shell "canNOT delete pods" "kubectl auth can-i delete pods --as=$SA7 -n trb-cka24 | grep -qx no"
shell "canNOT list pods in default" "kubectl auth can-i list pods --as=$SA7 -n default | grep -qx no"

# ---------------------------------------------------------------- Question 8
q 8 16 "web-dp-cka06-trb reachable"
ready "deployment has its replica ready" web-cka06-trb web-dp-cka06-trb
shell "image is a real httpd tag" \
  "! kubectl get deploy web-dp-cka06-trb -n web-cka06-trb -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q 'fake'"
expect "service selector matches the pods" "web-cka06" \
  get svc web-service-cka06-trb -n web-cka06-trb -o "jsonpath={.spec.selector.app}"
expect "targetPort corrected to 80" "80" \
  get svc web-service-cka06-trb -n web-cka06-trb -o "jsonpath={.spec.ports[0].targetPort}"
endpoints_at_least "service has an endpoint" web-cka06-trb web-service-cka06-trb 1

# ---------------------------------------------------------------- Question 9
q 9 10 "NetworkPolicy allows white, denies black"
exists "networkpolicy still exists" networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb
shell "policy allows port 80" \
  "kubectl get networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb -o jsonpath='{.spec.ingress[*].ports[*].port}' | grep -q 80"
shell "white pod can reach the service" \
  "kubectl exec cyan-white-cka28-trb1 -n default -- wget -qO- --timeout=5 http://cyan-svc-cka28-trb.cyan-ns-cka28-trb:80 >/dev/null 2>&1"
shell "black pod still cannot reach it" \
  "! kubectl exec cyan-black-cka28-trb -n default -- wget -qO- --timeout=5 http://cyan-svc-cka28-trb.cyan-ns-cka28-trb:80 >/dev/null 2>&1"
note "the connectivity checks need a policy-enforcing CNI; on a CNI without policy support the black check will fail"

# --------------------------------------------------------------- Question 10
q 10 6 "Rollback, record, scale"
shell "image rolled back to a working nginx tag" \
  "! kubectl get deploy app-wl07 -n dev-wl07 -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -q 'does-not-exist'"
expect "scaled to 5 replicas" "5" get deploy app-wl07 -n dev-wl07 -o "jsonpath={.spec.replicas}"
file_nonempty "/root/rolling-back-record.txt written" /root/rolling-back-record.txt
file_has "record names the nginx image in use" /root/rolling-back-record.txt "nginx"

report
