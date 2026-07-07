#!/usr/bin/env python3
# ps_verify.py
# Self-contained checker: simulates push_swap operations on stack a/b.
#
# Usage:
#   ./push_swap <args> | python3 ps_verify.py <args>
#
# Reads the SAME integer args push_swap received (top of stack = first arg),
# reads the operation stream from stdin, applies them, then prints:
#   OK    -> stack a sorted ascending (top = smallest) and stack b empty
#   KO    -> anything else
#   Error -> invalid operation in the stream
#
# Each argv token is split on whitespace, so "1 2 3" and 1 2 3 both work.

import sys


def parse_numbers(argv):
    nums = []
    for token in argv:
        for piece in token.split():
            nums.append(int(piece))
    return nums


def apply_op(op, a, b):
    if op == "sa":
        if len(a) > 1:
            a[0], a[1] = a[1], a[0]
    elif op == "sb":
        if len(b) > 1:
            b[0], b[1] = b[1], b[0]
    elif op == "ss":
        apply_op("sa", a, b)
        apply_op("sb", a, b)
    elif op == "pa":
        if b:
            a.insert(0, b.pop(0))
    elif op == "pb":
        if a:
            b.insert(0, a.pop(0))
    elif op == "ra":
        if a:
            a.append(a.pop(0))
    elif op == "rb":
        if b:
            b.append(b.pop(0))
    elif op == "rr":
        apply_op("ra", a, b)
        apply_op("rb", a, b)
    elif op == "rra":
        if a:
            a.insert(0, a.pop())
    elif op == "rrb":
        if b:
            b.insert(0, b.pop())
    elif op == "rrr":
        apply_op("rra", a, b)
        apply_op("rrb", a, b)
    else:
        return False
    return True


def main():
    try:
        a = parse_numbers(sys.argv[1:])
    except ValueError:
        print("Error")
        return 1
    b = []
    for line in sys.stdin:
        op = line.strip()
        if op == "":
            continue
        if not apply_op(op, a, b):
            print("Error")
            return 1
    if not b and a == sorted(a):
        print("OK")
        return 0
    print("KO")
    return 1


if __name__ == "__main__":
    sys.exit(main())
