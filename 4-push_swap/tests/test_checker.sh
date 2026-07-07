#!/usr/bin/env bash
# test_checker.sh - valida comportamento do checker (bonus) per subject Chapter VIII.
#
# Pula graciosamente se o checker nao estiver compilado (make bonus).
#
# Usage: ./test_checker.sh

. "$(dirname "$0")/lib.sh"
need_ps_bin

if ! need_chk_bin; then
	info "Execute 'make bonus' para compilar o checker e habilitar estes testes"
	summary
	exit 0
fi

# ---------------------------------------------------------------------------
title "Sem argumentos: nenhuma saida e exit 0"
# ---------------------------------------------------------------------------
out="$("$CHK_BIN" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && [ -z "$out" ]; then
	pass "sem argumentos: nenhuma saida e exit 0"
else
	fail "esperado saida vazia e exit 0. rc=$rc saida='$out'"
fi

# ---------------------------------------------------------------------------
title "Argumento nao inteiro: Error no stderr"
# ---------------------------------------------------------------------------
err="$("$CHK_BIN" "abc" 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para argumento nao inteiro 'abc'"
else
	fail "esperado 'Error' no stderr e exit != 0. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "String vazia como argumento: Error no stderr"
# ---------------------------------------------------------------------------
err="$("$CHK_BIN" "" 1 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para string vazia: ./checker \"\" 1"
else
	fail "esperado 'Error'. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "Argumento fora do range de int: Error no stderr"
# ---------------------------------------------------------------------------
err="$("$CHK_BIN" "2147483648" 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para valor acima do INT_MAX (2147483648)"
else
	fail "esperado 'Error' para 2147483648. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "Duplicatas: Error no stderr"
# ---------------------------------------------------------------------------
err="$("$CHK_BIN" 1 2 1 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para duplicatas '1 2 1'"
else
	fail "esperado 'Error' para duplicatas. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "Stack ja ordenada, sem operacoes: OK"
# ---------------------------------------------------------------------------
out="$(printf "" | "$CHK_BIN" 1 2 3 2>/dev/null)"
rc=$?
if [ "$out" = "OK" ] && [ $rc -eq 0 ]; then
	pass "OK para '1 2 3' sem operacoes (ja ordenado)"
else
	fail "esperado 'OK'. rc=$rc saida='$out'"
fi

# ---------------------------------------------------------------------------
title "Stack nao ordenada, sem operacoes: KO"
# ---------------------------------------------------------------------------
out="$(printf "" | "$CHK_BIN" 3 2 1 2>/dev/null)"
if [ "$out" = "KO" ]; then
	pass "KO para '3 2 1' sem operacoes"
else
	fail "esperado 'KO'. saida='$out'"
fi

# ---------------------------------------------------------------------------
title "Stack B nao vazia no final: KO"
# ---------------------------------------------------------------------------
out="$(printf "pb\n" | "$CHK_BIN" 1 2 3 2>/dev/null)"
if [ "$out" = "KO" ]; then
	pass "KO quando stack B nao esta vazia apos operacoes"
else
	fail "esperado 'KO' (B nao vazia apos pb). saida='$out'"
fi

# ---------------------------------------------------------------------------
title "Operacao invalida: Error no stderr"
# ---------------------------------------------------------------------------
err="$(printf "foo\n" | "$CHK_BIN" 3 2 1 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para operacao desconhecida 'foo'"
else
	fail "esperado 'Error'. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "Operacao malformada (letra maiuscula): Error no stderr"
# ---------------------------------------------------------------------------
err="$(printf "SA\n" | "$CHK_BIN" 3 2 1 2>&1 >/dev/null)"
rc=$?
if [ $rc -ne 0 ] && [ "$err" = "Error" ]; then
	pass "Error para operacao malformada 'SA'"
else
	fail "esperado 'Error' para 'SA'. rc=$rc stderr='$err'"
fi

# ---------------------------------------------------------------------------
title "Todas as 11 operacoes validas sao aceitas"
# ---------------------------------------------------------------------------
NUMS="$(rand_nums 20)"
# shellcheck disable=SC2086
err="$(printf "sa\nsb\nss\npb\npa\nra\nrb\nrr\nrra\nrrb\nrrr\n" \
	| "$CHK_BIN" $NUMS 2>&1 >/dev/null)"
if [ "$err" != "Error" ]; then
	pass "11 operacoes validas nao produziram Error"
else
	fail "operacoes validas causaram Error no stderr"
fi

# ---------------------------------------------------------------------------
title "Integracao: push_swap | checker em varios tamanhos"
# ---------------------------------------------------------------------------
for n in 3 5 10 50 100; do
	NUMS="$(rand_nums "$n")"
	OPS="$("$PS_BIN" $NUMS 2>/dev/null)"
	# shellcheck disable=SC2086
	out="$(printf "%s" "$OPS" | "$CHK_BIN" $NUMS 2>/dev/null)"
	if [ "$out" = "OK" ]; then
		pass "n=$n: push_swap | checker = OK"
	else
		fail "n=$n: esperado 'OK', obtido='$out'"
		info "primeiras 5 ops: $(printf "%s" "$OPS" | head -5)"
	fi
done

summary
