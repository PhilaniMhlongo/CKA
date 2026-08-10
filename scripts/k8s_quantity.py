#!/usr/bin/env python3
"""Parse and compare Kubernetes resource quantities.

Importable by validation scripts, and usable directly from bash:

    python3 scripts/k8s_quantity.py equals "$LIMIT" 500Mi   # exit 0 if equal
    python3 scripts/k8s_quantity.py value 1Gi               # prints 1073741824.0

Comparing parsed values rather than raw strings means a learner who writes
"0.5" instead of "500m", or "1Gi" instead of "1024Mi", is not marked wrong for
a cosmetic difference the cluster does not care about.
"""

import sys

# Binary suffixes are checked first so the decimal table never shadows them
# ("Mi" would otherwise be truncated by the "M" entry).
BINARY_SUFFIXES = {
    "Ki": 1024**1,
    "Mi": 1024**2,
    "Gi": 1024**3,
    "Ti": 1024**4,
    "Pi": 1024**5,
    "Ei": 1024**6,
}

DECIMAL_SUFFIXES = {
    "n": 1e-9,
    "u": 1e-6,
    "m": 1e-3,
    "k": 1e3,
    "M": 1e6,
    "G": 1e9,
    "T": 1e12,
    "P": 1e15,
    "E": 1e18,
}


def parse_quantity(value):
    """Parse a quantity string ("100m", "1", "0.5", "128Mi", "1Gi") to a float.

    Returns None for an empty/absent value so callers can distinguish "unset"
    from "set to zero".
    """
    if value is None:
        return None
    value = str(value).strip()
    if not value:
        return None
    for suffix, factor in BINARY_SUFFIXES.items():
        if value.endswith(suffix):
            return float(value[: -len(suffix)]) * factor
    for suffix, factor in DECIMAL_SUFFIXES.items():
        if value.endswith(suffix):
            return float(value[: -len(suffix)]) * factor
    return float(value)


def equal(left, right, tolerance=1e-9):
    """True when two quantities denote the same amount."""
    lhs = parse_quantity(left)
    rhs = parse_quantity(right)
    if lhs is None or rhs is None:
        return False
    return abs(lhs - rhs) <= tolerance * max(1.0, abs(rhs))


def main(argv):
    if len(argv) == 4 and argv[1] == "equals":
        return 0 if equal(argv[2], argv[3]) else 1
    if len(argv) == 3 and argv[1] == "value":
        parsed = parse_quantity(argv[2])
        if parsed is None:
            print("unset", file=sys.stderr)
            return 1
        print(parsed)
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
