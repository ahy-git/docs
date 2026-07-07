#!/usr/bin/env python3
# agg.py - read integers from stdin, print "size,strategy,min,avg,max".
#
# Usage: <counts> | python3 agg.py <size> <strategy>
import sys

size     = sys.argv[1]
strategy = sys.argv[2] if len(sys.argv) > 2 else "unknown"
vals     = [int(x) for x in sys.stdin.read().split()]
if not vals:
    print(f"{size},{strategy},0,0.0,0")
    sys.exit(0)
mn  = min(vals)
mx  = max(vals)
avg = sum(vals) / len(vals)
print(f"{size},{strategy},{mn},{avg:.1f},{mx}")
