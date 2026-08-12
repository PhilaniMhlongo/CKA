mkdir -p /tmp/exam/kustomize-adv/base /tmp/exam/kustomize-adv/overlays/production

# ---- base ----
cat <<'EOF' > /tmp/exam/kustomize-adv/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: nginx:1.25
          ports:
            - containerPort: 80
EOF

cat <<'EOF' > /tmp/exam/kustomize-adv/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-svc
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 80
EOF

cat <<'EOF' > /tmp/exam/kustomize-adv/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# ---- production overlay ----
cat <<'EOF' > /tmp/exam/kustomize-adv/overlays/production/probe-patch.yaml
- op: add
  path: /spec/template/spec/containers/0/readinessProbe
  value:
    httpGet:
      path: /
      port: 80
    initialDelaySeconds: 5
EOF

cat <<'EOF' > /tmp/exam/kustomize-adv/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namespace: d8f3b6a1c2e4-prod
namePrefix: prod-
replicas:
  - name: api
    count: 3
commonAnnotations:
  owner: platform-team
patches:
  - path: probe-patch.yaml
    target:
      kind: Deployment
      name: api
secretGenerator:
  - name: app-secret
    literals:
      - API_KEY=abc123
EOF

# Apply and verify
kubectl apply -k /tmp/exam/kustomize-adv/overlays/production/
kubectl get deployment,svc,secret -n d8f3b6a1c2e4-prod
kubectl get deployment prod-api -n d8f3b6a1c2e4-prod \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
