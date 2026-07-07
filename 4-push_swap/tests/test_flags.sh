#!/usr/bin/env bash
# test_flags.sh - strategy selectors and --bench behavior.
#
# Subject flags: --simple --medium --complex --adaptive --bench
#   - each selector must still produce a correctly sorting op stream
#   - --bench prints metrics to STDERR only (ops stay on stdout)
#   - an unknown flag must be an Error
#
# Usage: ./test_flags.sh [count]

. "$(dirname "$0")/lib.sh"
need_ps_bin

COUNT="${1:-100}"
NUMS="$(rand_nums "$COUNT")"

# verify a selector sorts correctly
check_selector() {
	local flag="$1"
	local ops res
	# shellcheck disable=SC2086
	ops="$("$PS_BIN" "$flag" $NUMS 2>/dev/null)"
	if [ -n "$CHECKER" ]; then
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | "$CHECKER" $NUMS 2>/dev/null)"
	else
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | $VERIFIER $NUMS 2>/dev/null)"
	fi
	if [ "$res" = "OK" ]; then
		pass "$flag ordena corretamente ($(printf "%s" "$ops" | grep -c .) ops)"
	else
		fail "$flag NAO ordenou ($res)"
	fi
}

title "Cada seletor ordena corretamente ($COUNT numeros)"
check_selector --simple
check_selector --medium
check_selector --complex
check_selector --adaptive

title "Default (sem flag) == adaptive"
# shellcheck disable=SC2086
ops_default="$("$PS_BIN" $NUMS 2>/dev/null | grep -c .)"
# shellcheck disable=SC2086
ops_adapt="$("$PS_BIN" --adaptive $NUMS 2>/dev/null | grep -c .)"
if [ "$ops_default" = "$ops_adapt" ]; then
	pass "default e --adaptive geram o mesmo numero de ops ($ops_default)"
else
	info "default=$ops_default ops, --adaptive=$ops_adapt ops (verifique design)"
fi

title "--bench manda metricas para STDERR, ops para STDOUT"
# shellcheck disable=SC2086
bench_out="$("$PS_BIN" --bench $NUMS 2>/tmp/ps_bench_err)"
bench_err="$(cat /tmp/ps_bench_err)"
if printf "%s" "$bench_out" | grep -qE '^(sa|sb|ss|pa|pb|ra|rb|rr|rra|rrb|rrr)$'; then
	pass "stdout contem apenas operacoes"
else
	fail "stdout do --bench nao parece ser so operacoes"
fi
title "Campos obrigatorios no stderr do --bench"
for field in bench disorder strategy complexity total; do
	if printf "%s" "$bench_err" | grep -q "^${field}"; then
		pass "campo '${field}' presente"
	else
		fail "campo '${field}' AUSENTE no stderr"
	fi
done

title "Contagem de cada operacao no --bench"
for op in sa sb ss pa pb ra rb rr rra rrb rrr; do
	if printf "%s" "$bench_err" | grep -q "^${op}: "; then
		pass "campo '$op' presente"
	else
		fail "campo '$op' AUSENTE"
	fi
done

title "Flag invalida deve ser Error"
out="$("$PS_BIN" --turbo 1 2 3 2>/tmp/ps_err)"
err="$(cat /tmp/ps_err)"
if [ -z "$out" ] && printf "%s" "$err" | grep -q "Error"; then
	pass "--turbo rejeitada com Error"
else
	info "--turbo -> stdout='$out' stderr='$err' (politica do aluno)"
fi

title "Flag sem numeros nao deve quebrar"
out="$("$PS_BIN" --simple 2>/tmp/ps_err)"
err="$(cat /tmp/ps_err)"
if [ -z "$out" ]; then
	pass "--simple sem numeros nao imprime ops"
else
	info "--simple sem numeros -> stdout='$out'"
fi

summary
