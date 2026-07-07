#!/usr/bin/env bash
# test_stability.sh - stress test: large inputs, crashes, infinite loops,
# wrong sorts and determinism.
#
# For each trial it checks:
#   - no crash (segfault / non-zero unexpected exit)
#   - no timeout (catches infinite loops)
#   - the op stream actually sorts (via verifier)
#   - same input -> same output (deterministic)
#
# Usage: ./test_stability.sh [size] [iters] [timeout_seconds]

. "$(dirname "$0")/lib.sh"
need_ps_bin

SIZE="${1:-1000}"
ITERS="${2:-30}"
TMO="${3:-10}"

TIMEOUT_BIN="timeout"
command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN="gtimeout"
if ! command -v "$TIMEOUT_BIN" >/dev/null 2>&1; then
	info "timeout nao disponivel: loops infinitos nao serao detectados"
	TIMEOUT_BIN=""
fi

run_ps() {
	if [ -n "$TIMEOUT_BIN" ]; then
		"$TIMEOUT_BIN" "$TMO" "$PS_BIN" "$@"
	else
		"$PS_BIN" "$@"
	fi
}

title "Stress: $ITERS rodadas de $SIZE numeros (timeout ${TMO}s)"
crashes=0
timeouts=0
wrong=0
i=0
worst=0
while [ "$i" -lt "$ITERS" ]; do
	nums="$(rand_nums "$SIZE")"
	# shellcheck disable=SC2086
	ops="$(run_ps $nums 2>/dev/null)"
	code=$?
	if [ "$code" -eq 124 ]; then
		timeouts=$((timeouts + 1))
		fail "rodada $i: TIMEOUT (possivel loop infinito)"
		i=$((i + 1))
		continue
	fi
	if [ "$code" -ge 128 ]; then
		crashes=$((crashes + 1))
		fail "rodada $i: CRASH (sinal $((code - 128)))"
		i=$((i + 1))
		continue
	fi
	n="$(printf "%s" "$ops" | grep -c .)"
	[ "$n" -gt "$worst" ] && worst="$n"
	if [ -n "$CHECKER" ]; then
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | "$CHECKER" $nums 2>/dev/null)"
	else
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | $VERIFIER $nums 2>/dev/null)"
	fi
	if [ "$res" != "OK" ]; then
		wrong=$((wrong + 1))
		fail "rodada $i: nao ordenou ($res)"
	fi
	i=$((i + 1))
done

if [ "$crashes" -eq 0 ] && [ "$timeouts" -eq 0 ] && [ "$wrong" -eq 0 ]; then
	pass "$ITERS rodadas de $SIZE: sem crash, sem timeout, todas ordenaram"
	info "pior contagem de operacoes: $worst"
else
	info "crashes=$crashes timeouts=$timeouts erros=$wrong"
fi

title "Determinismo: mesma entrada -> mesma saida"
nums="$(rand_nums "$SIZE")"
# shellcheck disable=SC2086
run1="$(run_ps $nums 2>/dev/null | md5sum)"
# shellcheck disable=SC2086
run2="$(run_ps $nums 2>/dev/null | md5sum)"
if [ "$run1" = "$run2" ]; then
	pass "saida identica em 2 execucoes (deterministico)"
else
	fail "saida diferente entre execucoes (nao deterministico)"
fi

title "Entradas patologicas grandes"
# fully reversed -> max disorder
rev="$(python3 -c "print(' '.join(str(x) for x in range($SIZE, 0, -1)))")"
# shellcheck disable=SC2086
ops="$(run_ps $rev 2>/dev/null)"; code=$?
if [ "$code" -eq 124 ]; then
	fail "invertido $SIZE: TIMEOUT"
elif [ "$code" -ge 128 ]; then
	fail "invertido $SIZE: CRASH"
else
	if [ -n "$CHECKER" ]; then
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | "$CHECKER" $rev 2>/dev/null)"
	else
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | $VERIFIER $rev 2>/dev/null)"
	fi
	[ "$res" = "OK" ] && pass "invertido $SIZE ordenou ($(printf '%s' "$ops" | grep -c .) ops)" \
		|| fail "invertido $SIZE: $res"
fi

# already sorted -> should be few/zero ops
srt="$(python3 -c "print(' '.join(str(x) for x in range(1, $SIZE + 1)))")"
# shellcheck disable=SC2086
ops="$(run_ps $srt 2>/dev/null)"
n="$(printf "%s" "$ops" | grep -c .)"
info "ja ordenado $SIZE -> $n operacoes (ideal: 0)"

summary
