# Check pod status - expect CrashLoopBackOff
kubectl get pods -n shopping

# Inspect events and last termination reason
kubectl describe pod -n shopping -l app=webapp

# Check logs, including the previous crashed container
kubectl logs -n shopping -l app=webapp --previous
# Expect something like: exec: "ngin": executable file not found in $PATH

# Fix the command (either remove the override or point it at the real binary)
kubectl edit deployment webapp -n shopping
# under spec.template.spec.containers[0], remove the bad `command: ["ngin"]`
# line entirely so the image's default entrypoint (nginx) runs, or set:
#   command: ["nginx", "-g", "daemon off;"]

# Confirm the rollout completes and pods are Running/Ready
kubectl rollout status deployment webapp -n shopping
kubectl get pods -n shopping
