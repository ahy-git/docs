#!/usr/bin/env bash
# compare_algos.sh - run all four strategies on the SAME inputs and compare
# operation counts side by side, across different disorder profiles.
#
# Also reports which strategy --adaptive picked (from --bench, if available)
# and verifies every strategy actually sorts.
#
# Usage: ./compare_algos.sh [size]

. "$(dirname "$0")/lib.sh"
need_ps_bin

SIZE="${1:-100}"

# build a profile of given size and disorder kind via python
make_profile() {
	python3 - "$SIZE" "$1" <<'PYEOF'
import sys, random
size, kind = int(sys.argv[1]), sys.argv[2]
base = list(range(1, size + 1))
if kind == "sorted":
    out = base
elif kind == "reverse":
    out = base[::-1]
elif kind == "nearly":
    out = base[:]
    swaps = max(1, size // 20)
    for _ in range(swaps):
        i = random.randrange(size); j = random.randrange(size)
        out[i], out[j] = out[j], out[i]
else:  # random
    out = base[:]; random.shuffle(out)
print(" ".join(str(x) for x in out))
PYEOF
}

# ops_count flag nums...
ops_count() {
	local flag="$1"; shift
	# shellcheck disable=SC2086
	"$PS_BIN" "$flag" "$@" 2>/dev/null | grep -c .
}

# sorts_ok flag nums...
sorts_ok() {
	local flag="$1"; shift
	local ops res
	# shellcheck disable=SC2086
	ops="$("$PS_BIN" "$flag" $* 2>/dev/null)"
	if [ -n "$CHECKER" ]; then
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | "$CHECKER" $* 2>/dev/null)"
	else
		# shellcheck disable=SC2086
		res="$(printf "%s\n" "$ops" | $VERIFIER $* 2>/dev/null)"
	fi
	[ "$res" = "OK" ]
}

# adaptive_pick nums...  -> strategy string from --bench, or "?"
adaptive_pick() {
	# shellcheck disable=SC2086
	"$PS_BIN" --bench --adaptive "$@" 2>&1 >/dev/null \
		| grep -i "strategy" | head -1 | sed 's/.*strategy[: ]*//I'
}

compare_profile() {
	local kind="$1"
	local nums
	nums="$(make_profile "$kind")"
	title "Perfil: $kind ($SIZE numeros)"

	# shellcheck disable=SC2086
	local s_simple s_medium s_complex s_adapt
	# shellcheck disable=SC2086
	s_simple="$(ops_count --simple $nums)"
	# shellcheck disable=SC2086
	s_medium="$(ops_count --medium $nums)"
	# shellcheck disable=SC2086
	s_complex="$(ops_count --complex $nums)"
	# shellcheck disable=SC2086
	s_adapt="$(ops_count --adaptive $nums)"

	printf "  %-12s %8s\n" "estrategia" "ops"
	printf "  %-12s %8s\n" "----------" "--------"
	printf "  %-12s %8s\n" "simple"   "$s_simple"
	printf "  %-12s %8s\n" "medium"   "$s_medium"
	printf "  %-12s %8s\n" "complex"  "$s_complex"
	printf "  %-12s %8s\n" "adaptive" "$s_adapt"

	# shellcheck disable=SC2086
	local pick
	pick="$(adaptive_pick $nums)"
	[ -n "$pick" ] && info "adaptive escolheu: $pick"

	# verify each one sorts
	local bad=0
	for f in --simple --medium --complex --adaptive; do
		# shellcheck disable=SC2086
		if sorts_ok "$f" $nums; then
			:
		else
			bad=1
			fail "$f NAO ordenou no perfil $kind"
		fi
	done
	[ "$bad" -eq 0 ] && pass "todas as 4 estrategias ordenaram ($kind)"
}

compare_profile sorted
compare_profile nearly
compare_profile random
compare_profile reverse

title "Leitura rapida"
info "Esperado: simple bom em baixa desordem; complex bom em alta desordem;"
info "adaptive deve seguir o melhor dos tres conforme o disorder."

summary
