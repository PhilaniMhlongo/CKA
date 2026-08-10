# Confirm the pod is stuck Pending with no node assigned
kubectl get pod stuck-pod -n triage -o wide
kubectl describe pod stuck-pod -n triage
# Events will show nothing scheduling it at all (no FailedScheduling event
# either) - that absence is the clue: the scheduler itself isn't running.

# Check the scheduler
kubectl get pods -n kube-system | grep scheduler
# Likely CrashLoopBackOff or not Ready

# Look at why via crictl (kubectl logs may not work if the pod never registers)
sudo crictl ps -a | grep kube-scheduler
SCHED_ID=$(sudo crictl ps -a | grep kube-scheduler | awk '{print $1}' | head -n1)
sudo crictl logs "$SCHED_ID" 2>&1 | tail -n 30
# Look for something like:
#   "open /etc/kubernetes/scheduler-wrong.conf: no such file or directory"

# Inspect and fix the static pod manifest
sudo cat /etc/kubernetes/manifests/kube-scheduler.yaml | grep kubeconfig
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
# Fix --kubeconfig back to /etc/kubernetes/scheduler.conf, save

# Wait for kubelet to recreate the static pod, then confirm it's healthy
kubectl get pods -n kube-system | grep scheduler

# stuck-pod (and new pods) should now get scheduled
kubectl get pod stuck-pod -n triage -o wide
