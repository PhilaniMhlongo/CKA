# Question
# DOMAIN: ServicesNetworking
# There is a deployment named nodeport-deployment in the relative namespace

# Tasks:
# 1. Configure the deployment so it exposes container port 80, name=http, protocol TCP
# 2. Create a new Service named nodeport-service of type NodePort in the relative
#    namespace, exposing port 80 -> targetPort 80, protocol TCP, on nodePort 30080
# 3. Create a second Service named nodeport-headless in the relative namespace that
#    resolves to the individual Pod IPs rather than to a single virtual IP
#    (a headless Service), also on port 80 / targetPort 80, protocol TCP

# Verify:
#    curl http://<NODE_IP>:30080
#    kubectl run dnstest --rm -it --image=busybox:stable --restart=Never -n relative \
#      -- nslookup nodeport-headless.relative.svc.cluster.local
#    (the headless lookup returns one A record per Pod, not a single ClusterIP)

# Video Link

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Concepts -> Services, Load Balancing, and Networking -> Service
# https://kubernetes.io/docs/concepts/services-networking/service/
# (headless) Concepts -> Services... -> Service -> Headless Services
# https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
