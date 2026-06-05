#!/bin/bash

# ============================================================
# Function test runner for get_next_line
# Compiles and runs mandatory and bonus separately.
# Each main is self-verifying: exit code 0 means all subtests
# passed, non-zero means at least one failed.
# Each main is tested with multiple BUFFER_SIZE values to
# catch buffer-dependent bugs.
# ============================================================

LOG_DIR="logs"
TEST_DIR="testscripts"
TMP_BIN="test_bin"
PASSOU=0
FALHOU=0
SEM_TESTE=0

BUFFER_SIZES="1 42 1024 9999"

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/func_*.log
rm -f "$TMP_BIN"
rm -f *.o

echo "🧪 Rodando testes de funcao..."
echo "----------------------------------------"

run_test() {
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
		log="$LOG_DIR/func_$tag.log"

		cc -Wall -Wextra -Werror -D BUFFER_SIZE=$bs \
			"$main_file" $srcs -o "$TMP_BIN" > "$log" 2>&1

		if [ $? -ne 0 ]; then
			echo "❌ COMPILA   : $tag"
			echo "" >> "$log"
			echo "=== RESULTADO: ERRO DE COMPILACAO ===" >> "$log"
			FALHOU=$((FALHOU + 1))
			continue
		fi

		./"$TMP_BIN" > "$log" 2>&1
		status_exec=$?

		if [ "$status_exec" -eq 0 ]; then
			total=$(grep -a "TOTAL FAILS" "$log" | tail -n 1)
			echo "✅ PASSOU    : $tag  ($total)"
			echo "" >> "$log"
			echo "=== RESULTADO: PASSOU ===" >> "$log"
			PASSOU=$((PASSOU + 1))
		elif [ "$status_exec" -eq 1 ]; then
			total=$(grep -a "TOTAL FAILS" "$log" | tail -n 1)
			echo "❌ FALHOU    : $tag  ($total)"
			fails_inline=$(grep -a "^FAIL" "$log" | head -n 5)
			if [ -n "$fails_inline" ]; then
				echo "$fails_inline" | sed 's/^/             /'
			fi
			echo "" >> "$log"
			echo "=== RESULTADO: FALHOU ===" >> "$log"
			FALHOU=$((FALHOU + 1))
		else
			echo "💥 CRASH     : $tag (exit $status_exec)"
			echo "" >> "$log"
			echo "=== RESULTADO: CRASH / EXIT INESPERADO ===" >> "$log"
			echo "Exit status: $status_exec" >> "$log"
			FALHOU=$((FALHOU + 1))
		fi

		rm -f "$TMP_BIN"
	done
}

run_test "$TEST_DIR/get_next_line_main.c" \
	"get_next_line.c get_next_line_utils.c" \
	"mandatory"

run_test "$TEST_DIR/get_next_line_bonus_main.c" \
	"get_next_line_bonus.c get_next_line_utils_bonus.c" \
	"bonus"

rm -f "$TMP_BIN"
rm -f *.o

echo "----------------------------------------"
echo "🏁 Testes de funcao concluidos!"
echo "   ✅ Passou     : $PASSOU"
echo "   ❌ Falhou     : $FALHOU"
echo "   ⚪ Sem teste  : $SEM_TESTE"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"