# Question: Onboard a User via CSR + Kubeconfig (Cluster Architecture - harder than exam)

# A new developer needs certificate-based access to namespace d8f3b6a1c2e4-dev.
# Work in a local directory ./csr-work (or set WORKDIR).

# Task
# 1. Generate a private key dev-user.key and a CSR with CN=dev-user, O=dev-team
# 2. Create a CertificateSigningRequest object named dev-user with
#    signerName kubernetes.io/kube-apiserver-client and usages [client auth]
# 3. Approve it and extract the issued certificate to dev-user.crt
# 4. Create RoleBinding dev-user-edit in d8f3b6a1c2e4-dev binding the
#    built-in ClusterRole 'edit' to User dev-user (namespace-scoped!)
# 5. Build a self-contained kubeconfig at ./csr-work/dev-user.kubeconfig
#    (embedded certs) and prove it works:
#      kubectl --kubeconfig ./csr-work/dev-user.kubeconfig get pods -n d8f3b6a1c2e4-dev
# 6. dev-user must NOT be able to list namespaces cluster-wide

# Documentation Reference
# Reference -> Access Authn/Authz -> Certificate Signing Requests
# https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/
