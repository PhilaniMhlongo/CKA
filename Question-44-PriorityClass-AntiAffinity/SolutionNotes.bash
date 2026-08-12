# Create the PriorityClasses and both pods
cat <<'EOF' > priority-pods.yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: eda9e0ec987a-high-priority
value: 1000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: eda9e0ec987a-low-priority
value: 100
globalDefault: false
preemptionPolicy: PreemptLowerPriority
---
apiVersion: v1
kind: Pod
metadata:
  name: high-priority
  namespace: eda9e0ec987a-scheduling
  labels:
    priority: high
spec:
  priorityClassName: eda9e0ec987a-high-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              priority: low
          topologyKey: kubernetes.io/hostname
  containers:
    - name: nginx
      image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: low-priority
  namespace: eda9e0ec987a-scheduling
  labels:
    priority: low
spec:
  priorityClassName: eda9e0ec987a-low-priority
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              priority: high
          topologyKey: kubernetes.io/hostname
  containers:
    - name: nginx
      image: nginx
EOF
kubectl apply -f priority-pods.yaml

# Verify placement (pods must not share a node)
kubectl get pods -n eda9e0ec987a-scheduling -o wide
