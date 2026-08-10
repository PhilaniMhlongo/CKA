# Add container port to deployment
kubectl patch deployment nodeport-deployment -n relative -p '{
  "spec":{"template":{"spec":{"containers":[{
    "name":"nginx",
    "ports":[{"name":"http","containerPort":80,"protocol":"TCP"}]
  }]}}}}'
kubectl get deploy nodeport-deployment -n relative -o wide

# Create NodePort service on 30080
cat <<'EOF' > svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: relative
spec:
  type: NodePort
  selector:
    app: nodeport-deployment
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    nodePort: 30080
EOF
kubectl apply -f svc.yaml
kubectl get svc nodeport-service -n relative -o wide
# Test: curl http://<nodeIP>:30080

# Create the headless service - clusterIP: None is what makes it headless, so
# DNS returns one A record per Pod instead of a single virtual IP. A headless
# service cannot also be type NodePort; these are two separate Services.
cat <<'EOF' > headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-headless
  namespace: relative
spec:
  clusterIP: None
  selector:
    app: nodeport-deployment
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF
kubectl apply -f headless.yaml
kubectl get svc nodeport-headless -n relative -o wide   # CLUSTER-IP shows None

# Confirm DNS returns the individual pod IPs
kubectl run dnstest --rm -it --image=busybox:stable --restart=Never -n relative \
  -- nslookup nodeport-headless.relative.svc.cluster.local
