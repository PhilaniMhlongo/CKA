#!/usr/bin/env bash
# Seeds the intentionally broken workload for Set 1, Question 10.
kubectl create namespace troubleshoot --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-app
  namespace: troubleshoot
spec:
  replicas: 2
  selector:
    matchLabels:
      app: failing-app
  template:
    metadata:
      labels:
        app: failing-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 8080
        resources:
          limits:
            memory: 32Mi
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
YAML
echo "   seeded: deployment/failing-app in namespace troubleshoot (broken on purpose)"
