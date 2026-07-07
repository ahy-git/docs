#!/usr/bin/env bash
# test_shuf_ops.sh - testes baseados em shuf com checker_linux.
#
# Teste 1: 500 numeros aleatorios (0-9999), conta operacoes do push_swap
# Teste 2: ARG fixo com --complex verificado pelo checker_linux
# Teste 3: 500 numeros com --bench, saida do bench em bench.txt, verifica com checker_linux
#
# Usage: ./test_shuf_ops.sh
#
# Requer: shuf (coreutils), checker_linux na raiz do projeto

. "$(dirname "$0")/lib.sh"
need_ps_bin

CHECKER_LINUX="$PROJECT_DIR/checker_linux"
BENCH_FILE="/tmp/bench_$$.txt"

# ---------------------------------------------------------------------------
need_checker_linux() {
	if [ ! -x "$CHECKER_LINUX" ]; then
		info "checker_linux nao encontrado em '$CHECKER_LINUX' — pulando testes que dependem dele"
		return 1
	fi
	return 0
}

need_shuf() {
	if ! command -v shuf >/dev/null 2>&1; then
		info "shuf nao disponivel — pulando testes que dependem dele"
		return 1
	fi
	return 0
}

# ---------------------------------------------------------------------------
# Teste 1: shuf -i 0-9999 -n 500 | push_swap | wc -l
# ---------------------------------------------------------------------------
title "Teste 1: 500 numeros aleatorios (0-9999) — contagem de operacoes"

if need_shuf; then
	ARGS="$(shuf -i 0-9999 -n 500 | tr '\n' ' ')"

	OPS_COUNT="$("$PS_BIN" $ARGS 2>/dev/null | grep -c .)"

	info "Operacoes geradas: $OPS_COUNT"

	if [ "$OPS_COUNT" -gt 0 ]; then
		pass "push_swap gerou $OPS_COUNT operacoes para 500 numeros"
	else
		fail "push_swap nao gerou operacoes para 500 numeros"
	fi

	# Limite informal da norma: <= 5500 para n=500
	if [ "$OPS_COUNT" -le 5500 ]; then
		pass "dentro do limite de 5500 ops (obtido: $OPS_COUNT)"
	else
		fail "acima do limite de 5500 ops (obtido: $OPS_COUNT)"
	fi
fi

# ---------------------------------------------------------------------------
# Teste 2: ARG fixo com --complex verificado pelo checker_linux
# ---------------------------------------------------------------------------
title "Teste 2: ARG fixo com --complex | checker_linux"

ARG="4 67 3 87 23"
info "Entrada: $ARG"

if need_checker_linux; then
	OPS="$("$PS_BIN" --complex $ARG 2>/dev/null)"
	OPS_N="$(printf '%s\n' "$OPS" | grep -c .)"
	info "Operacoes geradas (--complex): $OPS_N"

	RESULT="$(printf '%s\n' "$OPS" | "$CHECKER_LINUX" $ARG 2>/dev/null)"
	info "checker_linux respondeu: $RESULT"

	if [ "$RESULT" = "OK" ]; then
		pass "--complex '$ARG' | checker_linux = OK"
	else
		fail "--complex '$ARG' | checker_linux = $RESULT (esperado OK)"
	fi
fi

# ---------------------------------------------------------------------------
# Teste 3: 500 numeros com --bench, bench.txt e checker_linux
# ---------------------------------------------------------------------------
title "Teste 3: 500 numeros com --bench | checker_linux (bench salvo em bench.txt)"

if need_shuf && need_checker_linux; then
	ARGS="$(shuf -i 0-9999 -n 500 | tr '\n' ' ')"

	OPS="$("$PS_BIN" --bench $ARGS 2>"$BENCH_FILE")"
	OPS_N="$(printf '%s\n' "$OPS" | grep -c .)"

	info "Operacoes geradas (--bench): $OPS_N"

	if [ -s "$BENCH_FILE" ]; then
		info "bench.txt gerado ($(wc -l < "$BENCH_FILE") linhas)"
		# mostra as primeiras 3 linhas do bench como informacao
		while IFS= read -r line; do
			info "  bench: $line"
		done < <(head -3 "$BENCH_FILE")
	else
		info "bench.txt vazio ou nao gerado pelo --bench"
	fi

	RESULT="$(printf '%s\n' "$OPS" | "$CHECKER_LINUX" $ARGS 2>/dev/null)"
	info "checker_linux respondeu: $RESULT"

	if [ "$RESULT" = "OK" ]; then
		pass "--bench 500 numeros | checker_linux = OK"
	else
		fail "--bench 500 numeros | checker_linux = $RESULT (esperado OK)"
	fi

	# limpa arquivo temporario
	rm -f "$BENCH_FILE"
fi

summary
