#!/usr/bin/env bash
# test_performance.sh - operation-count benchmark vs the subject thresholds.
#
# Subject targets:
#   100 nums : pass <2000, good <1500, excellent <700
#   500 nums : pass <12000, good <8000, excellent <5500
#
# Usage: ./test_performance.sh [iters]   (default 100 iterations)

. "$(dirname "$0")/lib.sh"
need_ps_bin

ITERS="${1:-100}"

bench_size() {
	local count="$1"
	local results=()
	local i=0
	title "$count numeros - $ITERS rodadas"
	while [ "$i" -lt "$ITERS" ]; do
		local nums ops
		nums="$(rand_nums "$count")"
		# shellcheck disable=SC2086
		ops="$("$PS_BIN" $nums 2>/dev/null | grep -c .)"
		results+=("$ops")
		i=$((i + 1))
	done
	# stats via stats.py for median/avg (avoid heredoc+pipe stdin clash)
	printf "%s\n" "${results[@]}" | python3 "$SCRIPT_DIR/stats.py" "$count"
	# hard pass/fail on worst case
	local worst=0
	for r in "${results[@]}"; do
		[ "$r" -gt "$worst" ] && worst="$r"
	done
	local limit
	[ "$count" = "100" ] && limit=2000 || limit=12000
	if [ "$worst" -lt "$limit" ]; then
		pass "$count nums: pior caso $worst < $limit"
	else
		fail "$count nums: pior caso $worst >= $limit"
	fi
}

bench_size 100
bench_size 500

title "Sanidade extra: 3 e 5 numeros (limites classicos 3 e 12 ops)"
for trip in "2 1 3" "3 2 1" "3 1 2"; do
	# shellcheck disable=SC2086
	ops="$("$PS_BIN" $trip 2>/dev/null | grep -c .)"
	if [ "$ops" -le 3 ]; then
		pass "[$trip] -> $ops ops (<=3)"
	else
		fail "[$trip] -> $ops ops (>3)"
	fi
done
i=0
worst5=0
while [ "$i" -lt 50 ]; do
	nums="$(rand_nums 5 1 100)"
	# shellcheck disable=SC2086
	ops="$("$PS_BIN" $nums 2>/dev/null | grep -c .)"
	[ "$ops" -gt "$worst5" ] && worst5="$ops"
	i=$((i + 1))
done
if [ "$worst5" -le 12 ]; then
	pass "5 nums: pior caso em 50 rodadas = $worst5 (<=12)"
else
	fail "5 nums: pior caso $worst5 (>12)"
fi

summary
