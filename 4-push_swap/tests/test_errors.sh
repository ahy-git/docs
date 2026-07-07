#!/usr/bin/env bash
# test_errors.sh - parsing and error-management edge cases.
#
# Rules tested:
#   ERROR cases  -> stdout empty AND stderr contains "Error"
#   EMPTY cases  -> stdout empty AND stderr empty (program just returns)
#   Policy cases -> behavior is up to the student; we only report it
#
# Note: negative numbers are passed directly (e.g. -42). We never pass a bare
# "--" as a shell separator, because it would reach the binary as a literal
# argument and pollute the test. "--" and "-" are tested as real inputs.
#
# Usage: ./test_errors.sh

. "$(dirname "$0")/lib.sh"
need_ps_bin

# run_case "label" EXPECT arg1 arg2 ...     EXPECT = ERROR | EMPTY
run_case() {
	local label="$1"
	local expect="$2"
	shift 2
	local out err
	out="$("$PS_BIN" "$@" 2>/tmp/ps_err)"
	err="$(cat /tmp/ps_err)"
	if [ "$expect" = "ERROR" ]; then
		if [ -z "$out" ] && printf "%s" "$err" | grep -q "Error"; then
			pass "$label"
		else
			fail "$label (stdout='$out' stderr='$err')"
		fi
	else
		if [ -z "$out" ] && [ -z "$err" ]; then
			pass "$label"
		else
			fail "$label (stdout='$out' stderr='$err')"
		fi
	fi
}

# report_case "label" arg1 ...   (informational, never fails)
report_case() {
	local label="$1"
	shift
	local out err
	out="$("$PS_BIN" "$@" 2>/tmp/ps_err)"
	err="$(cat /tmp/ps_err)"
	if printf "%s" "$err" | grep -q "Error"; then
		info "$label -> rejeita (Error)"
	elif [ -z "$out" ] && [ -z "$err" ]; then
		info "$label -> aceita / nada impresso"
	else
		info "$label -> aceita / gera ops"
	fi
}

title "Casos que NAO devem imprimir nada (EMPTY)"
run_case "sem argumentos"            EMPTY
run_case "um numero (42)"            EMPTY 42
run_case "um numero negativo (-42)"  EMPTY -42
run_case "um zero"                   EMPTY 0

title "Argumentos nao numericos (ERROR)"
run_case "letra simples"             ERROR a
run_case "palavra"                   ERROR one
run_case "num com letra (1a)"        ERROR 1a
run_case "letra com num (a1)"        ERROR a1
run_case "num no meio (1 2 three)"   ERROR 1 2 three
run_case "decimal (1.5)"             ERROR 1.5
run_case "hex (0x10)"                ERROR 0x10
run_case "virgula (1,2)"             ERROR 1,2

title "Sinais e formatos malformados (ERROR)"
run_case "mais menos (+-5)"          ERROR +-5
run_case "menos mais (-+5)"          ERROR -+5
run_case "num com menos (1-2)"       ERROR 1-2
run_case "num com mais (1+2)"        ERROR 1+2
run_case "menos no fim (5-)"         ERROR 5-
run_case "so mais (+)"               ERROR +
run_case "so menos (-)"              ERROR -
run_case "dois menos (--)"           ERROR --

title "Overflow / fora do range int (ERROR)"
run_case "INT_MAX + 1"               ERROR 2147483648
run_case "INT_MIN - 1"               ERROR -2147483649
run_case "muito grande"              ERROR 99999999999999999999
run_case "muito negativo"            ERROR -99999999999999999999
run_case "overflow no meio"          ERROR 1 2147483648 2

title "Duplicados (ERROR)"
run_case "dup adjacente"             ERROR 1 2 2
run_case "dup separado"              ERROR 3 2 3
run_case "dup negativos"             ERROR -1 -1
run_case "dup zero"                  ERROR 0 0
run_case "dup em string"             ERROR "1 2 3 2"

title "Limites validos (NAO deve dar Error)"
report_case "INT_MAX sozinho"        2147483647
report_case "INT_MIN sozinho"        -2147483648
report_case "INT_MAX e INT_MIN"      -2147483648 2147483647

title "Casos dependentes de politica (apenas reporta)"
report_case "string vazia"           ""
report_case "so espacos"             "   "
report_case "tab"                    "	"
report_case "vazia entre nums"       1 "" 3
report_case "mais a esquerda (+5)"   +5
report_case "menos zero (-0)"        -0
report_case "mais zero (+0)"         +0
report_case "zeros a esquerda (007)" 007
report_case "zero duplo (00)"        00
report_case "espaco antes (' 5')"    " 5"

summary
