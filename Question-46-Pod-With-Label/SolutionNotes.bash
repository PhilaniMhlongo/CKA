# kubectl run applies the label run=<name> by default; --labels makes it explicit
kubectl run nginx-pod --image=nginx:1.19 -n 7b43d4b5300b-app-team1 --labels=run=nginx-pod

# Verify
kubectl get pod nginx-pod -n 7b43d4b5300b-app-team1 --show-labels
