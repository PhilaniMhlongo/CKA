# 1. Snapshot the current expirations
mkdir -p /tmp/exam
kubeadm certs check-expiration > /tmp/exam/cert-expiration-before.txt
cat /tmp/exam/cert-expiration-before.txt

# 2. Renew only the apiserver certificate
kubeadm certs renew apiserver

# 3. Snapshot again
kubeadm certs check-expiration > /tmp/exam/cert-expiration-after.txt

# 4. Independent verification with openssl
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
# notAfter should now be ~1 year from today

# NOTE: the apiserver process reloads serving certs; on some setups you may
# restart it by briefly moving its manifest out of /etc/kubernetes/manifests
