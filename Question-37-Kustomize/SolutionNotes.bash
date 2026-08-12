# Build the directory structure
mkdir -p /tmp/exam/kustomize/base
mkdir -p /tmp/exam/kustomize/overlays/production

# Base deployment
cat <<'EOF' > /tmp/exam/kustomize/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
EOF

cat <<'EOF' > /tmp/exam/kustomize/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF

# Production overlay
cat <<'EOF' > /tmp/exam/kustomize/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namespace: eda9e0ec987a-kustomize
replicas:
  - name: nginx
    count: 3
commonLabels:
  environment: production
configMapGenerator:
  - name: web-content
    files:
      - index.html
EOF
# NOTE: newer kustomize prefers `labels:` over the deprecated `commonLabels:`,
# but commonLabels still works for a fresh apply.

echo '<html><body><h1>Production</h1></body></html>' > /tmp/exam/kustomize/overlays/production/index.html

# Apply the overlay
kubectl create namespace eda9e0ec987a-kustomize --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k /tmp/exam/kustomize/overlays/production/

# Verify
kubectl get deployment,configmap -n eda9e0ec987a-kustomize --show-labels
