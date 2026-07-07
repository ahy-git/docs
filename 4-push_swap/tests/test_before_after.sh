#!/usr/bin/env bash
# test_before_after.sh - imprime os valores antes e depois da ordenacao,
# aplicando as operacoes geradas pelo push_swap sobre a stack simulada.
#
# Usage: ./test_before_after.sh [size]

. "$(dirname "$0")/lib.sh"
need_ps_bin

SIZE="${1:-10}"

# Aplica as operacoes geradas pelo push_swap e retorna a stack final via python
apply_ops() {
	local nums="$1"
	local ops="$2"
	python3 - "$nums" "$ops" <<'PYEOF'
import sys

nums = list(map(int, sys.argv[1].split()))
ops  = [o.strip() for o in sys.argv[2].splitlines() if o.strip()]

a = nums[:]
b = []

for op in ops:
    if op == "sa":
        if len(a) > 1: a[0], a[1] = a[1], a[0]
    elif op == "sb":
        if len(b) > 1: b[0], b[1] = b[1], b[0]
    elif op == "ss":
        if len(a) > 1: a[0], a[1] = a[1], a[0]
        if len(b) > 1: b[0], b[1] = b[1], b[0]
    elif op == "pa":
        if b: a.insert(0, b.pop(0))
    elif op == "pb":
        if a: b.insert(0, a.pop(0))
    elif op == "ra":
        if a: a.append(a.pop(0))
    elif op == "rb":
        if b: b.append(b.pop(0))
    elif op == "rr":
        if a: a.append(a.pop(0))
        if b: b.append(b.pop(0))
    elif op == "rra":
        if a: a.insert(0, a.pop())
    elif op == "rrb":
        if b: b.insert(0, b.pop())
    elif op == "rrr":
        if a: a.insert(0, a.pop())
        if b: b.insert(0, b.pop())

print(" ".join(map(str, a)))
PYEOF
}

show_before_after() {
	local label="$1"
	local nums="$2"
	local flag="${3:---adaptive}"

	title "Antes/Depois: $label ($SIZE numeros)"

	info "ANTES : $nums"

	local ops
	ops="$("$PS_BIN" "$flag" $nums 2>/dev/null)"

	local op_count
	op_count="$(printf '%s\n' "$ops" | grep -c .)"

	local after
	after="$(apply_ops "$nums" "$ops")"

	info "DEPOIS: $after"
	info "Operacoes ($flag): $op_count"

	# verifica corretude
	local result
	if [ -n "$CHECKER" ]; then
		result="$(printf '%s\n' "$ops" | "$CHECKER" $nums 2>/dev/null)"
	else
		result="$(printf '%s\n' "$ops" | $VERIFIER $nums 2>/dev/null)"
	fi

	if [ "$result" = "OK" ]; then
		pass "ordenacao correta ($label)"
	else
		fail "ordenacao incorreta ($label) - checker retornou: $result"
	fi
}

# numeros aleatorios
RAND="$(python3 -c "import random; a=list(range(1,$((SIZE+1)))); random.shuffle(a); print(' '.join(map(str,a)))")"

# numeros em ordem inversa
REVERSED="$(python3 -c "print(' '.join(map(str,range($SIZE,0,-1))))")"

# numeros quase ordenados (1 troca)
NEARLY="$(python3 -c "
import random
a=list(range(1,$((SIZE+1))))
i,j=random.sample(range($SIZE),2)
a[i],a[j]=a[j],a[i]
print(' '.join(map(str,a)))
")"

show_before_after "aleatorio"       "$RAND"
show_before_after "ordem_inversa"   "$REVERSED"
show_before_after "quase_ordenado"  "$NEARLY"

summary
