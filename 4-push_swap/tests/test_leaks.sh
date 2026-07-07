#!/usr/bin/env bash
# test_leaks.sh - memory leaks via valgrind, including error paths.
#
# Checks valid inputs AND error inputs (parsing must free everything too).
# On macOS, swap valgrind for `leaks` manually.
#
# Usage: ./test_leaks.sh [count]

. "$(dirname "$0")/lib.sh"
need_ps_bin

COUNT="${1:-100}"

if ! command -v valgrind >/dev/null 2>&1; then
	info "valgrind nao instalado. No macOS use: leaks --atExit -- $PS_BIN ..."
	exit 0
fi

VG="valgrind --leak-check=full --show-leak-kinds=all \
--errors-for-leak-kinds=all --error-exitcode=42 -q"

# leak_check "label" -- args...
leak_check() {
	local label="$1"
	shift
	# shellcheck disable=SC2086
	$VG "$PS_BIN" "$@" >/dev/null 2>/tmp/ps_vg
	local code=$?
	if [ "$code" -eq 42 ]; then
		fail "$label (vazamento/erro de memoria)"
		sed 's/^/      /' /tmp/ps_vg | head -n 12
	else
		pass "$label"
	fi
}

title "Caminhos validos"
leak_check "ordenado 1..5"        1 2 3 4 5
leak_check "invertido 5..1"       5 4 3 2 1
nums="$(rand_nums "$COUNT")"
# shellcheck disable=SC2086
leak_check "aleatorio $COUNT"     $nums

title "Caminhos de erro (parser deve liberar tudo)"
leak_check "nao numerico"         1 2 three
leak_check "overflow"             2147483648
leak_check "duplicado"            1 2 2
leak_check "malformado (--)"      --
leak_check "string vazia"         ""

title "Flags"
# shellcheck disable=SC2086
leak_check "--bench aleatorio"    --bench $nums
# shellcheck disable=SC2086
leak_check "--complex aleatorio"  --complex $nums

summary
