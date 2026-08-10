# Task 1 - namespaced Role in finance
kubectl create role pod-reader -n finance \
  --verb=get,list,watch \
  --resource=pods,configmaps

kubectl get role pod-reader -n finance -o yaml

# Task 2 - bind it to the ServiceAccount
kubectl create rolebinding report-runner-read -n finance \
  --role=pod-reader \
  --serviceaccount=finance:report-runner

# Task 3 - pods (only) in the hr namespace.
# The key idea: a ClusterRole defines *what* may be done, a RoleBinding decides
# *where*. Binding a ClusterRole with a RoleBinding grants those verbs only in
# the RoleBinding's namespace, so one cluster-scoped role can be reused across
# namespaces without ever granting cluster-wide access.
#
# Note that the built-in "view" ClusterRole is not usable here - it includes
# configmaps, which task 3 explicitly forbids in hr. So create a narrow one.
kubectl create clusterrole pod-lister \
  --verb=list \
  --resource=pods

kubectl create rolebinding report-runner-hr-read -n hr \
  --clusterrole=pod-lister \
  --serviceaccount=finance:report-runner

# Task 4 - verify the negative cases too. `kubectl auth can-i` with --as is the
# fastest way to check an identity's effective permissions.
SA=system:serviceaccount:finance:report-runner

kubectl auth can-i list pods       -n finance --as=$SA   # yes
kubectl auth can-i get configmaps  -n finance --as=$SA   # yes
kubectl auth can-i watch pods      -n finance --as=$SA   # yes
kubectl auth can-i list pods       -n hr      --as=$SA   # yes
kubectl auth can-i get configmaps  -n hr      --as=$SA   # no
kubectl auth can-i delete pods     -n finance --as=$SA   # no
kubectl auth can-i list pods       -n default --as=$SA   # no

# See everything the identity can do in one namespace:
kubectl auth can-i --list -n finance --as=$SA

# Common mistake: using `kubectl create clusterrolebinding` for task 3. That
# would grant list pods in EVERY namespace and fail the last check above.
