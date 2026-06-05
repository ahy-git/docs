#!/bin/bash

# ============================================================
# Memory-leak test runner for get_next_line
# Uses valgrind to check for leaks and invalid memory accesses.
# Tests mandatory and bonus separately, with multiple BUFFER_SIZE.
# ============================================================

LOG_DIR="logs"
TEST_DIR="testscripts"
TMP_BIN="leak_bin"
PASSOU=0
FALHOU=0
SEM_TESTE=0

BUFFER_SIZES="1 42"

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/leak_*.log
rm -f "$TMP_BIN"
rm -f *.o

if ! command -v valgrind > /dev/null 2>&1; then
	echo "❌ valgrind nao encontrado no PATH."
	echo "   No Linux: sudo apt install valgrind"
	echo "   No macOS: use o test_sanitizers.sh em vez deste."
	exit 1
fi

VG_OPTS="--leak-check=full \
--show-leak-kinds=all \
--track-origins=yes \
--errors-for-leak-kinds=definite,indirect \
--error-exitcode=42"

echo "🧪 Rodando testes de leak (valgrind)..."
echo "----------------------------------------"

run_leak() {
	main_file="$1"
	srcs="$2"
	label="$3"

	if [ ! -f "$main_file" ]; then
		echo "⚪ SEM TESTE : $label (main nao encontrada)"
		SEM_TESTE=$((SEM_TESTE + 1))
		return
	fi

	missing=""
	for src in $srcs; do
		if [ ! -f "$src" ]; then
			missing="$missing $src"
		fi
	done

	if [ -n "$missing" ]; then
		echo "❌ ARQUIVO   : $label (faltam:$missing)"
		FALHOU=$((FALHOU + 1))
		return
	fi

	for bs in $BUFFER_SIZES; do
		tag="${label}_bs${bs}"
		log="$LOG_DIR/leak_$tag.log"

		cc -Wall -Wextra -Werror -g -D BUFFER_SIZE=$bs \
			"$main_file" $srcs -o "$TMP_BIN" > "$log" 2>&1

		if [ $? -ne 0 ]; then
			echo "❌ COMPILA   : $tag"
			echo "" >> "$log"
			echo "=== RESULTADO: ERRO DE COMPILACAO ===" >> "$log"
			FALHOU=$((FALHOU + 1))
			continue
		fi

		valgrind $VG_OPTS ./"$TMP_BIN" > "$log" 2>&1
		vg_status=$?

		all_freed=$(grep -ac \
			"All heap blocks were freed -- no leaks are possible" "$log")
		errors=$(grep -a "ERROR SUMMARY:" "$log" \
			| tail -n 1 | sed 's/.*ERROR SUMMARY: //' \
			| awk '{print $1}' | tr -d ',')
		definitely=$(grep -a "definitely lost:" "$log" \
			| tail -n 1 | sed 's/.*definitely lost: //' \
			| awk '{print $1}' | tr -d ',')
		indirectly=$(grep -a "indirectly lost:" "$log" \
			| tail -n 1 | sed 's/.*indirectly lost: //' \
			| awk '{print $1}' | tr -d ',')

		if [ -z "$errors" ]; then
			errors="?"
		fi
		if [ -z "$definitely" ] && [ "$all_freed" -ge 1 ]; then
			definitely="0"
		elif [ -z "$definitely" ]; then
			definitely="?"
		fi
		if [ -z "$indirectly" ] && [ "$all_freed" -ge 1 ]; then
			indirectly="0"
		elif [ -z "$indirectly" ]; then
			indirectly="?"
		fi

		summary="def:$definitely ind:$indirectly err:$errors"

		if [ "$vg_status" -eq 0 ] \
			&& [ "$errors" = "0" ] \
			&& [ "$definitely" = "0" ] \
			&& [ "$indirectly" = "0" ]; then
			echo "✅ LIMPO     : $tag  ($summary)"
			echo "" >> "$log"
			echo "=== RESULTADO: SEM LEAKS ===" >> "$log"
			PASSOU=$((PASSOU + 1))
		else
			echo "❌ LEAK/ERRO : $tag  ($summary)"
			echo "" >> "$log"
			echo "=== RESULTADO: LEAK OU ERRO DETECTADO ===" >> "$log"
			echo "Valgrind exit status: $vg_status" >> "$log"
			FALHOU=$((FALHOU + 1))
		fi

		rm -f "$TMP_BIN"
	done
}

run_leak "$TEST_DIR/get_next_line_main.c" \
	"get_next_line.c get_next_line_utils.c" \
	"mandatory"

run_leak "$TEST_DIR/get_next_line_bonus_main.c" \
	"get_next_line_bonus.c get_next_line_utils_bonus.c" \
	"bonus"

rm -f "$TMP_BIN"
rm -f *.o

echo "----------------------------------------"
echo "🏁 Testes de leak concluidos!"
echo "   ✅ Limpo      : $PASSOU"
echo "   ❌ Leak/Erro  : $FALHOU"
echo "   ⚪ Sem teste  : $SEM_TESTE"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"
echo "   Inspecione qualquer log para o backtrace completo do valgrind."