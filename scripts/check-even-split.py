#!/usr/bin/env python3
"""Check that a workload's resource requests evenly divide its node's capacity.

Used by the resource-allocation questions (4 and 19). Rather than asserting a
hard-coded threshold, this compares the pods' effective requests against the
node's real `.status.allocatable`, which is what the exam scenario is actually
asking the candidate to reason about.

Passes when, for the requested resource:
  * every matching pod requests exactly the same amount,
  * the replicas together fit on the node (total <= allocatable), and
  * the replicas together claim at least --min-fraction of allocatable, i.e. the
    node was actually divided up rather than nudged by a token amount.

Exit code 0 on success, 1 on failure. Reasons are printed to stderr.
"""

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from k8s_quantity import parse_quantity  # noqa: E402


def kubectl_json(*args):
    out = subprocess.run(
        ["kubectl", *args, "-o", "json"],
        capture_output=True,
        text=True,
    )
    if out.returncode != 0:
        print(out.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    return json.loads(out.stdout)


def effective_request(pod_spec, resource):
    """Effective pod request: max(sum of app containers, largest init container).

    This mirrors how the scheduler sizes a pod, so a question that asks for init
    and app containers to match is scored the same way the scheduler sees it.
    """
    total = 0.0
    for container in pod_spec.get("containers", []):
        req = container.get("resources", {}).get("requests", {}).get(resource)
        parsed = parse_quantity(req)
        if parsed is None:
            return None
        total += parsed

    largest_init = 0.0
    for container in pod_spec.get("initContainers", []):
        req = container.get("resources", {}).get("requests", {}).get(resource)
        parsed = parse_quantity(req)
        if parsed is not None:
            largest_init = max(largest_init, parsed)

    return max(total, largest_init)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--namespace", default="default")
    parser.add_argument("--selector", required=True)
    parser.add_argument("--replicas", type=int, required=True)
    parser.add_argument("--resource", choices=["cpu", "memory"], required=True)
    parser.add_argument(
        "--min-fraction",
        type=float,
        default=0.55,
        help="Replicas together must claim at least this share of allocatable.",
    )
    parser.add_argument(
        "--max-fraction",
        type=float,
        default=1.0,
        help="Replicas together must leave at least 1 - this share as headroom.",
    )
    args = parser.parse_args()

    pods = kubectl_json(
        "get", "pods", "-n", args.namespace, "-l", args.selector
    )["items"]
    pods = [p for p in pods if p.get("status", {}).get("phase") == "Running"]

    if len(pods) != args.replicas:
        print(
            f"expected {args.replicas} running pods, found {len(pods)}",
            file=sys.stderr,
        )
        return 1

    requests = []
    for pod in pods:
        value = effective_request(pod["spec"], args.resource)
        if value is None or value == 0:
            print(
                f"pod {pod['metadata']['name']} has no {args.resource} request set",
                file=sys.stderr,
            )
            return 1
        requests.append(value)

    if len(set(requests)) != 1:
        print(
            f"pods do not request equal {args.resource}: {sorted(set(requests))}",
            file=sys.stderr,
        )
        return 1

    per_pod = requests[0]
    total = per_pod * args.replicas

    node_names = {p["spec"].get("nodeName") for p in pods if p["spec"].get("nodeName")}
    if not node_names:
        print("pods are not assigned to a node", file=sys.stderr)
        return 1

    # Score against the smallest node the replicas landed on: if the split fits
    # there, it fits everywhere they are actually running.
    allocatables = []
    for name in node_names:
        node = kubectl_json("get", "node", name)
        allocatable = parse_quantity(node["status"]["allocatable"][args.resource])
        allocatables.append((name, allocatable))
    node_name, allocatable = min(allocatables, key=lambda kv: kv[1])

    if total > allocatable * args.max_fraction:
        print(
            f"{args.replicas} x {per_pod} {args.resource} = {total} is "
            f"{total / allocatable:.0%} of allocatable {allocatable} on node "
            f"{node_name}; at most {args.max_fraction:.0%} may be claimed, "
            f"leave headroom for system workloads",
            file=sys.stderr,
        )
        return 1

    if total < allocatable * args.min_fraction:
        print(
            f"{args.replicas} x {per_pod} {args.resource} = {total} is only "
            f"{total / allocatable:.0%} of allocatable {allocatable} on node "
            f"{node_name}; the node was not divided among the replicas",
            file=sys.stderr,
        )
        return 1

    print(
        f"{args.resource}: {per_pod} per pod x {args.replicas} = {total} "
        f"({total / allocatable:.0%} of allocatable on {node_name})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
