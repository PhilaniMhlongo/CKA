# Question 18 - Update resource limits in place
# DOMAIN: WorkloadsScheduling
#
# Context:
#   A deployment named resource-app exists in the patch-ns namespace. Its
#   nginx container is limited to 200m CPU and 256Mi memory, which is too low
#   for the expected workload.
#
# Task:
#   Raise the nginx container's limits to 500m CPU and 512Mi memory.
#
# Constraints:
#   - Do not change the CPU or memory requests
#   - Do not change the image or the replica count
#   - The deployment must still have 2 available replicas when you are done
#
# Note:
#   `kubectl patch` is the intended tool here - the point of the exercise is to
#   practise updating a live object in place, and a strategic merge patch is the
#   shortest route. Grading looks only at the resulting cluster state.

#Documentation Reference
# Tip: Navigate the documentation manually to build familiarity with its structure
# Tasks -> Manage Kubernetes Objects -> Update API Objects in Place Using kubectl patch
# https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/
