#!/usr/bin/env bash
# test_adaptive.sh - verifica que --adaptive roteia para a estrategia correta
# conforme a faixa de disorder medida.
#
# Thresholds (sort_stubs.c / subject VI.3.3):
#   disorder < 0.2           -> simple   (stderr: "strategy: adaptive/simple")
#   0.2 <= disorder < 0.5   -> medium   (stderr: "strategy: adaptive/medium")
#   disorder >= 0.5          -> complex  (stderr: "strategy: adaptive/complex")
#
# Entradas deterministicas de tamanho 50 com disorders calculados:
#   low    : ordenado com 20 swaps de adjacentes  -> d =  20/1225 ~  1.63%
#   medium : primeira metade invertida            -> d = 300/1225 ~ 24.49%
#   high   : totalmente invertido                 -> d = 1.0      = 100.00%
#
# Tambem testa os limiares (bordas 0.2 e 0.5) com entradas precisas.
#
# Usage: ./test_adaptive.sh

. "$(dirname "$0")/lib.sh"
need_ps_bin

# ---------------------------------------------------------------------------
# Gerador de entradas com disorder conhecido
# ---------------------------------------------------------------------------
make_input() {
	python3 - "$1" <<'PYEOF'
import sys
kind = sys.argv[1]
n = 50
if kind == "low":
    # sorted + 20 adjacent swaps -> 20 inversions, d = 20/1225 ~ 1.6%
    arr = list(range(1, n + 1))
    for i in range(0, 40, 2):
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
elif kind == "medium":
    # first half reversed -> C(25,2)=300 inversions, d = 300/1225 ~ 24.5%
    arr = list(range(n // 2, 0, -1)) + list(range(n // 2 + 1, n + 1))
elif kind == "border_below":
    # n=20: first 9 reversed -> C(9,2)=36 inv, d=36/190=18.9% (< 0.2 -> simple)
    arr = list(range(9, 0, -1)) + list(range(10, 21))
elif kind == "border_above":
    # n=20: first 10 reversed -> C(10,2)=45 inv, d=45/190=23.7% (>= 0.2 -> medium)
    arr = list(range(10, 0, -1)) + list(range(11, 21))
elif kind == "border_high":
    # n=10: top half [6-10] then bottom half [1-5]
    # 5*5=25 cross-inversions out of C(10,2)=45, d=55.6% (>= 0.5 -> complex)
    arr = list(range(6, 11)) + list(range(1, 6))
else:
    arr = list(range(n, 0, -1))  # high: d = 1.0
print(" ".join(str(x) for x in arr))
PYEOF
}

# ---------------------------------------------------------------------------
# Calcula o disorder com o mesmo algoritmo de disorder.c
# ---------------------------------------------------------------------------
compute_disorder_pct() {
	python3 - "$1" <<'PYEOF'
import sys
arr = list(map(int, sys.argv[1].split()))
n = len(arr)
mistakes = 0
total = 0
for i in range(n):
    for j in range(i + 1, n):
        total += 1
        if arr[i] > arr[j]:
            mistakes += 1
d = (mistakes / total * 100) if total else 0.0
print(f"{d:.2f}%")
PYEOF
}

# ---------------------------------------------------------------------------
# Roda --adaptive --bench e verifica a estrategia escolhida
# ---------------------------------------------------------------------------
check_routing() {
	local label="$1"
	local nums="$2"
	local expected="$3"   # simple | medium | complex

	local bench_err
	# shellcheck disable=SC2086
	bench_err="$("$PS_BIN" --bench --adaptive $nums 2>&1 >/dev/null)"
	local strat
	strat="$(printf "%s" "$bench_err" | grep '^strategy: ' | head -1)"
	local dis
	dis="$(printf "%s" "$bench_err" | grep '^disorder: ' | head -1)"

	if printf "%s" "$strat" | grep -q "adaptive/${expected}"; then
		pass "$label -> $strat  ($dis)"
	else
		fail "$label -> esperado 'adaptive/${expected}', obtido: '$strat'  ($dis)"
	fi
}

# ---------------------------------------------------------------------------
# Verifica que --adaptive ainda ordena corretamente
# ---------------------------------------------------------------------------
check_sorts() {
	local label="$1"
	local nums="$2"
	# shellcheck disable=SC2086
	local res
	res="$(verify_sort $nums)"
	if [ "$res" = "OK" ]; then
		pass "$label ordena corretamente"
	else
		fail "$label nao ordenou ($res)"
	fi
}

# Pre-calcula entradas
LOW_NUMS="$(make_input low)"
MED_NUMS="$(make_input medium)"
HIG_NUMS="$(make_input high)"
BLW_NUMS="$(make_input border_below)"
BAB_NUMS="$(make_input border_above)"

title "Disorders das entradas de teste"
info "baixo  : $(compute_disorder_pct "$LOW_NUMS") (esperado <  20.00%) -> simple"
info "medio  : $(compute_disorder_pct "$MED_NUMS") (esperado 20-49.99%) -> medium"
info "alto   : $(compute_disorder_pct "$HIG_NUMS") (esperado >= 50.00%) -> complex"
info "borda- : $(compute_disorder_pct "$BLW_NUMS") (esperado <  20.00%) -> simple"
info "borda+ : $(compute_disorder_pct "$BAB_NUMS") (esperado >= 20.00%) -> medium"

title "Roteamento --adaptive por faixa de disorder"
check_routing "disorder baixo  (~1.6%)"  "$LOW_NUMS" simple
check_routing "disorder medio  (~24.5%)" "$MED_NUMS" medium
check_routing "disorder alto   (100%)"   "$HIG_NUMS" complex

title "Limiares de borda (0.2)"
check_routing "borda inferior (~18.9%, < 0.2)"  "$BLW_NUMS" simple
check_routing "borda superior (~23.7%, >= 0.2)" "$BAB_NUMS" medium

title "Limiar de borda (0.5): disorder exato >= 0.5"
# Reversed n=10: d = 1.0 (muito acima de 0.5)
HB_NUMS="$(make_input border_high)"
info "borda alta: $(compute_disorder_pct "$HB_NUMS") (esperado >= 50.00%) -> complex"
check_routing "borda alta (~55.6%, >= 0.5)" "$HB_NUMS" complex

title "--adaptive ordena corretamente em cada faixa"
check_sorts "disorder baixo"  "$LOW_NUMS"
check_sorts "disorder medio"  "$MED_NUMS"
check_sorts "disorder alto"   "$HIG_NUMS"

title "disorder reportado pelo --bench bate com o calculado"
for kind in low medium high; do
	nums="$(make_input "$kind")"
	expected_pct="$(compute_disorder_pct "$nums")"
	# shellcheck disable=SC2086
	reported="$("$PS_BIN" --bench --adaptive $nums 2>&1 >/dev/null \
		| grep '^disorder: ' | sed 's/disorder: //')"
	if [ "$reported" = "$expected_pct" ]; then
		pass "$kind: disorder=$reported (bate com calculo)"
	else
		fail "$kind: binario reportou '$reported', calculado '$expected_pct'"
	fi
done

summary
