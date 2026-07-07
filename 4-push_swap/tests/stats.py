#!/usr/bin/env python3
# stats.py - read operation counts (one per line) from stdin, print stats
# vs the subject thresholds for the given input size.
#
# Usage: <counts> | python3 stats.py <size>

import sys


def main():
    size = int(sys.argv[1])
    vals = sorted(int(x) for x in sys.stdin.read().split())
    if not vals:
        print("  (sem dados)")
        return
    n = len(vals)
    mn, mx = vals[0], vals[-1]
    avg = sum(vals) / n
    med = vals[n // 2] if n % 2 else (vals[n // 2 - 1] + vals[n // 2]) / 2
    if size == 100:
        pass_t, good_t, exc_t = 2000, 1500, 700
    else:
        pass_t, good_t, exc_t = 12000, 8000, 5500
    print(f"  min={mn}  max={mx}  avg={avg:.1f}  mediana={med}")
    print(f"  limites: passa<{pass_t}  bom<{good_t}  excelente<{exc_t}")
    if mx < exc_t:
        verdict = "EXCELENTE (pior caso)"
    elif mx < good_t:
        verdict = "BOM (pior caso)"
    elif mx < pass_t:
        verdict = "PASSA (pior caso)"
    else:
        verdict = "REPROVA (pior caso excede limite)"
    print(f"  veredito pelo PIOR caso: {verdict}")


if __name__ == "__main__":
    main()
