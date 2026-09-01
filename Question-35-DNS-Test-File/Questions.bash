# Question: DNS Test to File
# DOMAIN: ServicesNetworking

# Task
# 1. Create deployment dns-app (2 replicas, nginx) in namespace
#    eda9e0ec987a-dns-config
# 2. Create ClusterIP service dns-svc targeting it on port 80
# 3. Create pod dns-tester using image infoblox/dnstools that runs nslookup
#    on dns-svc and its FQDN, saving both results to /tmp/dns-test.txt
#    inside the pod

# Documentation Reference
# Tasks -> Administer a Cluster -> Debugging DNS Resolution
# https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
