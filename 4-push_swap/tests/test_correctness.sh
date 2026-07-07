#!/usr/bin/env bash
# test_correctness.sh - verifies the op stream actually sorts the stack.
#
# Uses ps_verify.py by default; set CHECKER=./checker_linux to use a real one.
#
# Usage: ./test_correctness.sh [random_count] [random_iters]

. "$(dirname "$0")/lib.sh"
need_ps_bin

RAND_COUNT="${1:-100}"
RAND_ITERS="${2:-20}"

# check_args "label" -- arg1 ...
check_args() {
	local label="$1"
	shift
	local res
	res="$(verify_sort "$@")"
	if [ "$res" = "OK" ]; then
		pass "$label"
	else
		fail "$label (verificador disse '$res')"
	fi
}

title "Casos triviais"
# already sorted / single -> empty op stream must still verify as OK
check_args "ja ordenado 1..5"        1 2 3 4 5
check_args "um elemento"             42
check_args "dois ordenados"          1 2
check_args "dois invertidos"         2 1
check_args "negativos ordenados"     -3 -2 -1 0 1
check_args "mistura neg/pos"         -5 3 -1 0 2

title "Todas as permutacoes de 3"
check_args "1 2 3" 1 2 3
check_args "1 3 2" 1 3 2
check_args "2 1 3" 2 1 3
check_args "2 3 1" 2 3 1
check_args "3 1 2" 3 1 2
check_args "3 2 1" 3 2 1

title "Permutacoes representativas de 4 e 5"
check_args "4 piores"  4 3 2 1
check_args "4 meio"    2 4 1 3
check_args "5 piores"  5 4 3 2 1
check_args "5 meio"    3 1 5 2 4
check_args "5 quase"   1 2 3 5 4

title "Entrada como string unica (split por espaco)"
check_args "string 5 4 3 2 1" "5 4 3 2 1"
check_args "string mista"     "10 -5 0 3 -1"

title "Aleatorios: $RAND_ITERS rodadas de $RAND_COUNT numeros"
local_ok=0
i=0
while [ "$i" -lt "$RAND_ITERS" ]; do
	nums="$(rand_nums "$RAND_COUNT")"
	# shellcheck disable=SC2086
	res="$(verify_sort $nums)"
	if [ "$res" = "OK" ]; then
		local_ok=$((local_ok + 1))
	else
		fail "rodada $i falhou ($res)"
	fi
	i=$((i + 1))
done
if [ "$local_ok" -eq "$RAND_ITERS" ]; then
	pass "todas as $RAND_ITERS rodadas aleatorias ordenaram"
fi

summary
