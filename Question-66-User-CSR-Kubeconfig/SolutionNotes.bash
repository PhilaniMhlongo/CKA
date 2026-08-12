WORKDIR="${WORKDIR:-$PWD/csr-work}"
mkdir -p "$WORKDIR" && cd "$WORKDIR"

# 1. Key + CSR (CN = username, O = group)
openssl genrsa -out dev-user.key 2048
openssl req -new -key dev-user.key -subj "/CN=dev-user/O=dev-team" -out dev-user.csr

# 2. CSR object
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dev-user
spec:
  request: $(base64 -w0 < dev-user.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
EOF

# 3. Approve and extract the certificate
kubectl certificate approve dev-user
kubectl get csr dev-user -o jsonpath='{.status.certificate}' | base64 -d > dev-user.crt

# 4. Namespace-scoped RoleBinding to the built-in 'edit' ClusterRole
kubectl create rolebinding dev-user-edit \
  --clusterrole=edit --user=dev-user -n d8f3b6a1c2e4-dev

# 5. Build the kubeconfig
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify --flatten \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
KC=dev-user.kubeconfig
kubectl config set-cluster kubernetes --kubeconfig="$KC" \
  --server="$SERVER" --certificate-authority=ca.crt --embed-certs=true
kubectl config set-credentials dev-user --kubeconfig="$KC" \
  --client-certificate=dev-user.crt --client-key=dev-user.key --embed-certs=true
kubectl config set-context dev-user@kubernetes --kubeconfig="$KC" \
  --cluster=kubernetes --user=dev-user --namespace=d8f3b6a1c2e4-dev
kubectl config use-context dev-user@kubernetes --kubeconfig="$KC"

# 6. Verify
kubectl --kubeconfig="$KC" get pods -n d8f3b6a1c2e4-dev           # works (empty list)
kubectl auth can-i create deployments --as=dev-user -n d8f3b6a1c2e4-dev   # yes
kubectl auth can-i list namespaces --as=dev-user                  # no
