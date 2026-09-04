#!/usr/bin/env bash
# Automatic marker — Ultimate CKA, Set 1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/checks.sh
source "$DIR/../lib/checks.sh"

preamble "Ultimate CKA — Set 1" "$DIR"

# ---------------------------------------------------------------- Question 1
q 1 6 "Secret secure-sec-cka12-arch"
exists "namespace secure-sys-cka12-arch exists" ns secure-sys-cka12-arch
exists "secret secure-sec-cka12-arch exists" secret secure-sec-cka12-arch -n secure-sys-cka12-arch
shell "key color decodes to darkblue" \
  "kubectl get secret secure-sec-cka12-arch -n secure-sys-cka12-arch -o jsonpath='{.data.color}' | base64 -d | grep -qx darkblue"

# ---------------------------------------------------------------- Question 2
q 2 8 "Pod looper-cka16-arch printing hello"
exists "pod looper-cka16-arch exists" pod looper-cka16-arch
pod_running "pod is Running" default looper-cka16-arch
contains "uses the busybox image" "busybox" \
  get pod looper-cka16-arch -o "jsonpath={.spec.containers[0].image}"
shell "logs contain 'hello'" \
  "kubectl logs looper-cka16-arch --tail=20 2>/dev/null | grep -q hello"

# ---------------------------------------------------------------- Question 3
q 3 10 "Sidecar tailing elastic-app.log"
exists "pod elastic-app-cka02-arch exists" pod elastic-app-cka02-arch
shell "pod has 2 containers" \
  "test \$(kubectl get pod elastic-app-cka02-arch -o jsonpath='{.spec.containers[*].name}' | wc -w) -eq 2"
contains "a container is named sidecar" "sidecar" \
  get pod elastic-app-cka02-arch -o "jsonpath={.spec.containers[*].name}"
shell "sidecar uses busybox" \
  "kubectl get pod elastic-app-cka02-arch -o jsonpath='{.spec.containers[?(@.name==\"sidecar\")].image}' | grep -q busybox"
shell "sidecar tails /var/log/elastic-app.log" \
  "kubectl get pod elastic-app-cka02-arch -o jsonpath='{.spec.containers[?(@.name==\"sidecar\")].command}{.spec.containers[?(@.name==\"sidecar\")].args}' | grep -q 'elastic-app.log'"
shell "both containers are ready" \
  "kubectl get pod elastic-app-cka02-arch -o jsonpath='{.status.containerStatuses[*].ready}' | grep -qx 'true true'"
shell "sidecar is printing the log to stdout" \
  "kubectl logs elastic-app-cka02-arch -c sidecar --tail=20 2>/dev/null | grep -q 'app log line'"

# ---------------------------------------------------------------- Question 4
q 4 10 "grape-pod-cka06-str shared emptyDir"
exists "namespace grape-cka06-str exists" ns grape-cka06-str
exists "pod grape-pod-cka06-str exists" pod grape-pod-cka06-str -n grape-cka06-str
expect "volume grape-vol-cka06-str is an emptyDir" "grape-vol-cka06-str" \
  get pod grape-pod-cka06-str -n grape-cka06-str -o "jsonpath={.spec.volumes[?(@.emptyDir)].name}"
shell "a container uses image nginx" \
  "kubectl get pod grape-pod-cka06-str -n grape-cka06-str -o jsonpath='{.spec.containers[*].image}' | grep -q nginx"
shell "a container uses image busybox" \
  "kubectl get pod grape-pod-cka06-str -n grape-cka06-str -o jsonpath='{.spec.containers[*].image}' | grep -q busybox"
shell "volume mounted at /var/log/nginx" \
  "kubectl get pod grape-pod-cka06-str -n grape-cka06-str -o json | grep -q '\"mountPath\": *\"/var/log/nginx\"'"
shell "same volume mounted at /usr/src" \
  "kubectl get pod grape-pod-cka06-str -n grape-cka06-str -o json | grep -q '\"mountPath\": *\"/usr/src\"'"
pod_running "pod is Running" grape-cka06-str grape-pod-cka06-str

# ---------------------------------------------------------------- Question 5
q 5 12 "DNS lookups recorded to file"
exists "pod nginx-resolver-cka06-svcn exists" pod nginx-resolver-cka06-svcn
exists "service nginx-resolver-service-cka06-svcn exists" svc nginx-resolver-service-cka06-svcn
endpoints_at_least "service has an endpoint" default nginx-resolver-service-cka06-svcn 1
file_nonempty "/root/CKA/nginx.svc.cka06.svcn written" /root/CKA/nginx.svc.cka06.svcn
file_has "service file names the service FQDN" /root/CKA/nginx.svc.cka06.svcn \
  "nginx-resolver-service-cka06-svcn.default.svc.cluster.local"
file_nonempty "/root/CKA/nginx.pod.cka06.svcn written" /root/CKA/nginx.pod.cka06.svcn
file_matches "pod file holds a pod DNS record" /root/CKA/nginx.pod.cka06.svcn \
  "[0-9]+-[0-9]+-[0-9]+-[0-9]+\.default\.pod\.cluster\.local"

# ---------------------------------------------------------------- Question 6
q 6 8 "LoadBalancer service wear-service-cka09-svcn"
exists "service wear-service-cka09-svcn exists" svc wear-service-cka09-svcn -n app-space
expect "type is LoadBalancer" "LoadBalancer" \
  get svc wear-service-cka09-svcn -n app-space -o "jsonpath={.spec.type}"
expect "port is 8080" "8080" \
  get svc wear-service-cka09-svcn -n app-space -o "jsonpath={.spec.ports[0].port}"
endpoints_at_least "service has 2 endpoints" app-space wear-service-cka09-svcn 2
note "EXTERNAL-IP stays <pending> on a bare-metal playground; not marked"

# ---------------------------------------------------------------- Question 7
q 7 8 "ServiceAccount permissions written to file"
file_nonempty "/opt/red-sa-cka23-arch written" /opt/red-sa-cka23-arch
file_has "names the deployments resource" /opt/red-sa-cka23-arch "resource:deployments"
file_has "lists the verbs get,list,watch" /opt/red-sa-cka23-arch "verbs:get,list,watch"

# ---------------------------------------------------------------- Question 8
q 8 8 "Broken template deployed"
exists "namespace app-cka07-trb exists" ns app-cka07-trb
exists "deployment app-cka07-trb exists" deploy app-cka07-trb -n app-cka07-trb
ready "deployment is fully ready" app-cka07-trb app-cka07-trb
shell "the template file was not modified" \
  "grep -q 'namespace: app-cka07-trb' /root/app-cka07-trb.yaml && grep -q 'image: nginx:1.25' /root/app-cka07-trb.yaml"

# ---------------------------------------------------------------- Question 9
q 9 12 "yello-cka20-trb scheduled despite the taint"
exists "pod yello-cka20-trb exists" pod yello-cka20-trb -n yello-cka20-trb
pod_running "pod is Running" yello-cka20-trb yello-cka20-trb
shell "pod tolerates app-type=yello" \
  "kubectl get pod yello-cka20-trb -n yello-cka20-trb -o json | tr -d ' \n' | grep -q '\"key\":\"app-type\"' && kubectl get pod yello-cka20-trb -n yello-cka20-trb -o json | tr -d ' \n' | grep -q '\"value\":\"yello\"'"
shell "the node taint is still in place" \
  "kubectl get nodes -o json | tr -d ' \n' | grep -q '\"key\":\"app-type\",\"value\":\"yello\"'"

# --------------------------------------------------------------- Question 10
q 10 18 "web-dp-cka17-trb running and stable"
exists "deployment web-dp-cka17-trb exists" deploy web-dp-cka17-trb -n web-cka17-trb
expect "PVC web-pvc-cka17-trb is Bound" "Bound" \
  get pvc web-pvc-cka17-trb -n web-cka17-trb -o "jsonpath={.status.phase}"
ready "deployment has its replica ready" web-cka17-trb web-dp-cka17-trb
shell "container command no longer references /bin/bsh" \
  "! kubectl get deploy web-dp-cka17-trb -n web-cka17-trb -o jsonpath='{.spec.template.spec.containers[0].command}' | grep -q 'bsh'"
shell "pod is not restarting" \
  "test \"\$(kubectl get pods -n web-cka17-trb -l app=web-dp-cka17-trb -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null)\" -le 2"

report
