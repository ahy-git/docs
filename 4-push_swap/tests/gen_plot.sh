#!/usr/bin/env bash
# gen_plot.sh - collect operation counts across input sizes and strategies.
#
# Produces:
#   - ps_perf.csv  (size,strategy,min,avg,max)
#   - ASCII chart on screen per strategy
#   - ps_perf.png  (if matplotlib is installed)
#
# Usage: ./gen_plot.sh [iters_per_size] [sizes...]
#   default iters   = 10
#   default sizes   = 5 50 100 200 300 500 1000 5000 10000
#
# Strategies always tested: adaptive simple medium complex
#
# Skip limits (impractical combinations):
#   simple  skipped for n > 500   (O(n²) generates millions of ops)
#   medium  skipped for n > 5000  (O(n√n) becomes very slow)

. "$(dirname "$0")/lib.sh"
need_ps_bin

ITERS="${1:-10}"
shift 2>/dev/null
SIZES=("$@")
if [ "${#SIZES[@]}" -eq 0 ]; then
	SIZES=(5 50 100 200 300 500 1000 5000 10000)
fi

STRATEGIES=(adaptive simple medium complex)
MAX_SIMPLE=500
MAX_MEDIUM=5000

CSV="ps_perf.csv"
PNG="ps_perf.png"

title "Coletando dados ($ITERS rodadas por tamanho x estrategia)"
printf "size,strategy,min,avg,max\n" > "$CSV"

for strategy in "${STRATEGIES[@]}"; do
	for size in "${SIZES[@]}"; do
		if [ "$strategy" = "simple" ] && [ "$size" -gt "$MAX_SIMPLE" ]; then
			info "n=$size $strategy -> pulado (O(n²) impraticavel acima de n=$MAX_SIMPLE)"
			continue
		fi
		if [ "$strategy" = "medium" ] && [ "$size" -gt "$MAX_MEDIUM" ]; then
			info "n=$size $strategy -> pulado (O(n√n) impraticavel acima de n=$MAX_MEDIUM)"
			continue
		fi

		results=()
		i=0
		while [ "$i" -lt "$ITERS" ]; do
			nums="$(rand_nums "$size")"
			# shellcheck disable=SC2086
			ops="$("$PS_BIN" "--${strategy}" $nums 2>/dev/null | grep -c .)"
			results+=("$ops")
			i=$((i + 1))
		done
		line="$(printf "%s\n" "${results[@]}" \
			| python3 "$SCRIPT_DIR/agg.py" "$size" "$strategy")"
		printf "%s\n" "$line" >> "$CSV"
		info "n=$size $strategy -> $line"
	done
done

title "Grafico"
python3 "$SCRIPT_DIR/plot.py" "$CSV" "$PNG"

printf "\nCSV: %s\n" "$CSV"
