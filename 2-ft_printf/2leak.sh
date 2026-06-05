#!/bin/bash

# ============================================================
# Teste de leaks do ft_printf
# Compila o projeto, cria main_test.c a partir de testscripts/
# e roda casos importantes com Valgrind
# ============================================================

LOG_DIR="logs_leaks"
TEST_DIR="testscripts"
TEST_SRC="$TEST_DIR/main_printf.c"
TMP_MAIN="main_test.c"
TMP_BIN="test_printf_bin"
PASSOU=0
FALHOU=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log
rm -f "$TMP_MAIN" "$TMP_BIN"

echo "🧠 Rodando teste de leaks do ft_printf..."
echo "----------------------------------------"

if ! command -v valgrind > /dev/null 2>&1; then
	echo "❌ Valgrind nao encontrado"
	echo "Instale ou verifique se o comando esta no PATH"
	exit 1
fi

if [ ! -f "$TEST_SRC" ]; then
	echo "❌ Arquivo de teste nao encontrado: $TEST_SRC"
	exit 1
fi

make fclean > "$LOG_DIR/make.log" 2>&1
make >> "$LOG_DIR/make.log" 2>&1

if [ $? -ne 0 ]; then
	echo "❌ ERRO NO MAKE"
	echo "Veja: $LOG_DIR/make.log"
	exit 1
fi

if [ ! -f "libftprintf.a" ]; then
	echo "❌ libftprintf.a nao foi criada"
	echo "Veja: $LOG_DIR/make.log"
	exit 1
fi

cp "$TEST_SRC" "$TMP_MAIN"

LINK_LIBS="libftprintf.a"
if [ -f "libft/libft.a" ]; then
	LINK_LIBS="$LINK_LIBS libft/libft.a"
fi

cc -Wall -Wextra -Werror "$TMP_MAIN" $LINK_LIBS -o "$TMP_BIN" \
	> "$LOG_DIR/compile_test.log" 2>&1

if [ $? -ne 0 ]; then
	echo "❌ ERRO AO COMPILAR TESTE"
	echo "Veja: $LOG_DIR/compile_test.log"
	rm -f "$TMP_MAIN"
	exit 1
fi

CASES=(
	"6|string NULL"
	"9|INT_MIN"
	"13|UINT_MAX"
	"17|hex UINT_MAX lower"
	"18|hex UINT_MAX upper"
	"20|pointer NULL"
	"23|todos os tipos"
	"24|caso misto pesado"
)

for item in "${CASES[@]}"; do
	id="${item%%|*}"
	name="${item#*|}"
	log="$LOG_DIR/leak_case_$id.log"

	valgrind \
		--leak-check=full \
		--show-leak-kinds=all \
		--errors-for-leak-kinds=all \
		--error-exitcode=42 \
		./"$TMP_BIN" ft "$id" > /dev/null 2> "$log"

	status=$?

	if [ "$status" -eq 0 ]; then
		echo "✅ SEM LEAK : $id - $name"
		PASSOU=$((PASSOU + 1))
	else
		echo "❌ LEAK/ERRO: $id - $name"
		echo "Veja: $log"
		FALHOU=$((FALHOU + 1))
	fi
done

rm -f "$TMP_MAIN" "$TMP_BIN"

echo "----------------------------------------"
echo "🏁 Testes de leak concluídos!"
echo "   ✅ Sem leak : $PASSOU"
echo "   ❌ Falhou   : $FALHOU"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"

if [ "$FALHOU" -ne 0 ]; then
	exit 1
fi

exit 0