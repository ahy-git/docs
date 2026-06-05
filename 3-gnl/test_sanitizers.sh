#!/bin/bash

# ============================================================
# Sanitizer test runner for get_next_line
# Recompiles with -fsanitize=address,undefined and runs the
# self-verifying mains. Catches memory errors and undefined
# behavior with precise file:line backtraces.
# ============================================================

LOG_DIR="logs"
TEST_DIR="testscripts"
TMP_BIN="san_bin"
PASSOU=0
FALHOU=0
SEM_TESTE=0

BUFFER_SIZES="1 42"

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/san_*.log
rm -f "$TMP_BIN"
rm -f *.o

SAN_FLAGS="-fsanitize=address,undefined \
-fno-sanitize-recover=all \
-fno-omit-frame-pointer \
-g -O1"

export ASAN_OPTIONS="detect_leaks=1:abort_on_error=0:halt_on_error=1"
export UBSAN_OPTIONS="print_stacktrace=1:halt_on_error=1"

echo "🧪 Rodando testes de sanitizers (ASan + UBSan)..."
echo "----------------------------------------"

run_san() {
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
		log="$LOG_DIR/san_$tag.log"

		cc -Wall -Wextra -Werror $SAN_FLAGS \
			-D BUFFER_SIZE=$bs \
			"$main_file" $srcs -o "$TMP_BIN" > "$log" 2>&1

		if [ $? -ne 0 ]; then
			echo "❌ COMPILA   : $tag"
			echo "" >> "$log"
			echo "=== RESULTADO: ERRO DE COMPILACAO ===" >> "$log"
			FALHOU=$((FALHOU + 1))
			continue
		fi

		./"$TMP_BIN" > "$log" 2>&1
		exit_status=$?

		asan_hit=$(grep -ac "AddressSanitizer\|LeakSanitizer" "$log")
		ubsan_hit=$(grep -ac "runtime error:" "$log")
		main_fails=$(grep -a "TOTAL FAILS" "$log" | tail -n 1)

		if [ "$exit_status" -eq 0 ] \
			&& [ "$asan_hit" -eq 0 ] \
			&& [ "$ubsan_hit" -eq 0 ]; then
			echo "✅ LIMPO     : $tag  ($main_fails)"
			echo "" >> "$log"
			echo "=== RESULTADO: SEM ERROS DE SANITIZER ===" >> "$log"
			PASSOU=$((PASSOU + 1))
		else
			motivo=""
			if [ "$asan_hit" -gt 0 ]; then
				motivo="$motivo ASan"
			fi
			if [ "$ubsan_hit" -gt 0 ]; then
				motivo="$motivo UBSan"
			fi
			if [ -z "$motivo" ] && [ "$exit_status" -ne 0 ]; then
				motivo=" exit=$exit_status"
			fi
			echo "❌ ERRO      : $tag $motivo"
			first_err=$(grep -aE "AddressSanitizer:|runtime error:|LeakSanitizer:" \
				"$log" | head -n 2)
			if [ -n "$first_err" ]; then
				echo "$first_err" | sed 's/^/             /'
			fi
			echo "" >> "$log"
			echo "=== RESULTADO: ERRO DE SANITIZER ===" >> "$log"
			FALHOU=$((FALHOU + 1))
		fi

		rm -f "$TMP_BIN"
	done
}

run_san "$TEST_DIR/get_next_line_main.c" \
	"get_next_line.c get_next_line_utils.c" \
	"mandatory"

run_san "$TEST_DIR/get_next_line_bonus_main.c" \
	"get_next_line_bonus.c get_next_line_utils_bonus.c" \
	"bonus"

rm -f "$TMP_BIN"
rm -f *.o

echo "----------------------------------------"
echo "🏁 Testes de sanitizers concluidos!"
echo "   ✅ Limpo      : $PASSOU"
echo "   ❌ Erro       : $FALHOU"
echo "   ⚪ Sem teste  : $SEM_TESTE"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"
echo "   Inspecione qualquer log para o backtrace completo."