#!/usr/bin/env bash
# test_bench_format.sh - verifica o formato exato da saida do --bench.
#
# Formato esperado no stderr (bench_report.c):
#   bench\n
#   disorder: XX.XX%\n         <- 2 casas decimais, sinal %
#   strategy: [adaptive/]<name>\n
#   complexity: <class>\n      <- "O(n^2)" | "O(n sqrt n)" | "O(n log n)"
#   total: <N>\n
#   sa: N\n  sb: N\n  ... rrr: N\n
#
# Usage: ./test_bench_format.sh [count]

. "$(dirname "$0")/lib.sh"
need_ps_bin

COUNT="${1:-50}"
NUMS="$(rand_nums "$COUNT")"

# shellcheck disable=SC2086
BENCH_ERR="$("$PS_BIN" --bench --adaptive $NUMS 2>&1 >/dev/null)"

title "Cabecalho 'bench'"
if printf "%s" "$BENCH_ERR" | grep -q '^bench$'; then
	pass "linha 'bench' presente como primeira linha de campo"
else
	fail "linha 'bench' ausente ou malformada"
	info "stderr completo: $(printf '%s' "$BENCH_ERR" | head -5)"
fi

title "disorder: formato numerico com 2 casas decimais"
dis_line="$(printf "%s" "$BENCH_ERR" | grep '^disorder: ')"
if [ -z "$dis_line" ]; then
	fail "campo 'disorder:' ausente"
else
	if printf "%s" "$dis_line" | grep -qE '^disorder: [0-9]+\.[0-9]{2}%$'; then
		pass "formato correto: '$dis_line'"
	else
		fail "formato incorreto: '$dis_line' (esperado 'disorder: N.NN%')"
	fi
fi

title "strategy: formato esperado por modo"
strat_line="$(printf "%s" "$BENCH_ERR" | grep '^strategy: ')"
if [ -z "$strat_line" ]; then
	fail "campo 'strategy:' ausente"
else
	if printf "%s" "$strat_line" | \
			grep -qE '^strategy: adaptive/(simple|medium|complex)$'; then
		pass "--adaptive: '$strat_line'"
	else
		fail "--adaptive: formato inesperado: '$strat_line'"
		info "esperado 'strategy: adaptive/(simple|medium|complex)'"
	fi
fi

title "strategy: --simple/--medium/--complex sem prefixo 'adaptive/'"
for flag in --simple --medium --complex; do
	expected_name="${flag#--}"
	# shellcheck disable=SC2086
	flag_err="$("$PS_BIN" --bench "$flag" $NUMS 2>&1 >/dev/null)"
	flag_strat="$(printf "%s" "$flag_err" | grep '^strategy: ')"
	if printf "%s" "$flag_strat" | \
			grep -qE "^strategy: ${expected_name}$"; then
		pass "$flag: '$flag_strat'"
	else
		fail "$flag: esperado 'strategy: ${expected_name}', obtido: '$flag_strat'"
	fi
done

title "complexity: classe valida de complexidade"
cplx_line="$(printf "%s" "$BENCH_ERR" | grep '^complexity: ')"
if [ -z "$cplx_line" ]; then
	fail "campo 'complexity:' ausente"
else
	if printf "%s" "$cplx_line" | \
			grep -qE "^complexity: O\(n(\^2|²| sqrt n|√n| log n)\)$"; then
		pass "classe valida: '$cplx_line'"
	else
		fail "classe invalida ou desconhecida: '$cplx_line'"
		info "esperado: 'O(n^2)'|'O(n²)' | 'O(n sqrt n)'|'O(n√n)' | 'O(n log n)'"
	fi
fi

title "complexity: coerencia entre strategy e complexity"
strat_name="$(printf "%s" "$strat_line" | sed 's/.*\///')"
cplx_name="$(printf "%s" "$cplx_line" | sed 's/complexity: //')"
ok=1
case "$strat_name" in
	simple)  [ "$cplx_name" = "O(n^2)" ]      || [ "$cplx_name" = "O(n²)" ]  || ok=0 ;;
	medium)  [ "$cplx_name" = "O(n sqrt n)" ] || [ "$cplx_name" = "O(n√n)" ] || ok=0 ;;
	complex) [ "$cplx_name" = "O(n log n)" ]   || ok=0 ;;
esac
if [ "$ok" -eq 1 ]; then
	pass "strategy='$strat_name' e complexity='$cplx_name' sao coerentes"
else
	fail "strategy='$strat_name' mas complexity='$cplx_name' (incompativel)"
fi

title "total: numero inteiro"
total_line="$(printf "%s" "$BENCH_ERR" | grep '^total: ')"
if [ -z "$total_line" ]; then
	fail "campo 'total:' ausente"
elif printf "%s" "$total_line" | grep -qE '^total: [0-9]+$'; then
	pass "total numerico: '$total_line'"
else
	fail "formato invalido: '$total_line'"
fi

title "total: soma das contagens individuais"
if [ -n "$total_line" ]; then
	declared_total="$(printf "%s" "$total_line" | grep -oE '[0-9]+')"
	computed_total="$(printf "%s" "$BENCH_ERR" \
		| grep -E '^(sa|sb|ss|pa|pb|ra|rb|rr|rra|rrb|rrr): ' \
		| grep -oE '[0-9]+' \
		| python3 -c 'import sys; print(sum(int(l) for l in sys.stdin))')"
	if [ "$declared_total" = "$computed_total" ]; then
		pass "total=$declared_total == soma dos campos ($computed_total)"
	else
		fail "total=$declared_total != soma dos campos ($computed_total)"
	fi
fi

title "Contadores individuais de operacao"
for op in sa sb ss pa pb ra rb rr rra rrb rrr; do
	op_line="$(printf "%s" "$BENCH_ERR" | grep "^${op}: ")"
	if printf "%s" "$op_line" | grep -qE "^${op}: [0-9]+$"; then
		pass "$op: '$op_line'"
	else
		fail "$op: ausente ou formato invalido (encontrado: '${op_line:-<nada>}')"
	fi
done

title "--bench nao aparece sem a flag"
# shellcheck disable=SC2086
plain_err="$("$PS_BIN" $NUMS 2>&1 >/dev/null)"
if [ -z "$plain_err" ]; then
	pass "sem --bench -> stderr vazio"
else
	fail "sem --bench -> stderr nao vazio: '$(printf "%s" "$plain_err" | head -3)'"
fi

summary
