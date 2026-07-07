#!/usr/bin/env bash
# test_basic.sh - normal, non-edge-case behavior and output format checks.
#
# Covers everyday usage:
#   - sorted input produces no operations
#   - typical unsorted inputs sort correctly within pass thresholds
#   - output format: only valid ops, one per line, separated by \n only
#   - args given separately or as a single quoted string behave the same
#
# Usage: ./test_basic.sh

. "$(dirname "$0")/lib.sh"
need_ps_bin

VALID_RE='^(sa|sb|ss|pa|pb|ra|rb|rr|rra|rrb|rrr)$'

title "Entrada ja ordenada nao deve gerar operacoes"
for inp in "1 2 3" "1 2 3 4 5" "-3 -1 0 2 7"; do
	# shellcheck disable=SC2086
	n="$("$PS_BIN" $inp 2>/dev/null | grep -c .)"
	if [ "$n" -eq 0 ]; then
		pass "[$inp] -> 0 ops"
	else
		fail "[$inp] -> $n ops (esperado 0)"
	fi
done

title "Entradas comuns ordenam corretamente"
for inp in "2 1" "3 2 1" "5 1 4 2 3" "10 -5 0 3 -1 8 2"; do
	# shellcheck disable=SC2086
	res="$(verify_sort $inp)"
	if [ "$res" = "OK" ]; then
		pass "[$inp] ordenou"
	else
		fail "[$inp] -> $res"
	fi
done

title "Formato de saida (so operacoes validas, uma por linha)"
nums="$(rand_nums 60)"
# shellcheck disable=SC2086
out="$("$PS_BIN" $nums 2>/dev/null)"
bad_lines=0
while IFS= read -r line; do
	[ -z "$line" ] && continue
	if ! printf "%s" "$line" | grep -qE "$VALID_RE"; then
		bad_lines=$((bad_lines + 1))
		info "linha invalida: '$line'"
	fi
done <<< "$out"
if [ "$bad_lines" -eq 0 ]; then
	pass "todas as linhas sao operacoes validas"
else
	fail "$bad_lines linha(s) com formato invalido"
fi

title "Sem espacos/caracteres extras nas linhas"
# shellcheck disable=SC2086
if printf "%s" "$out" | grep -qE ' |\t'; then
	fail "saida contem espacos ou tabs (apenas \\n e permitido)"
else
	pass "sem espacos/tabs na saida"
fi

title "Argumentos separados vs string unica geram a mesma saida"
sep="$("$PS_BIN" 5 3 1 4 2 2>/dev/null | md5sum)"
str="$("$PS_BIN" "5 3 1 4 2" 2>/dev/null | md5sum)"
if [ "$sep" = "$str" ]; then
	pass "'5 3 1 4 2' separado == string unica"
else
	fail "saida difere entre args separados e string unica"
fi

title "Saida termina com newline"
# shellcheck disable=SC2086
raw="$("$PS_BIN" 3 2 1 2>/dev/null; printf X)"
if printf "%s" "$raw" | grep -q $'\nX$' || [ "${raw: -1}" = "X" ]; then
	# last real char before X should be newline if there were ops
	last_two="${raw: -2}"
	if [ "$last_two" = $'\nX' ]; then
		pass "saida termina com \\n"
	else
		info "ultima sequencia: '${last_two}' (verifique newline final)"
	fi
else
	info "nao foi possivel determinar o newline final"
fi

summary
