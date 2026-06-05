#!/bin/bash

# ============================================================
# Mini-Moulinette caseira do ft_printf
# Compara ft_printf contra printf original
# Testa saida byte a byte e valor de retorno
# ============================================================

LOG_DIR="logs_printf"
TEST_DIR="testscripts"
TEST_SRC="$TEST_DIR/main_printf.c"
TMP_MAIN="main_test.c"
TMP_BIN="test_printf_bin"
FT_OUT="ft_stdout.tmp"
ORIG_OUT="orig_stdout.tmp"
FT_RET="ft_ret.tmp"
ORIG_RET="orig_ret.tmp"
PASSOU=0
FALHOU=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log
rm -f "$TMP_MAIN" "$TMP_BIN"
rm -f "$FT_OUT" "$ORIG_OUT" "$FT_RET" "$ORIG_RET"

echo "🧪 Rodando testes do ft_printf..."
echo "----------------------------------------"

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
	"1|empty string"
	"2|plain text"
	"3|char simples"
	"4|char com nul byte"
	"5|string normal"
	"6|string NULL"
	"7|int zero"
	"8|int negativo"
	"9|INT_MIN"
	"10|INT_MAX"
	"11|i e d misturados"
	"12|unsigned zero"
	"13|UINT_MAX"
	"14|hex zero"
	"15|hex lowercase"
	"16|hex uppercase"
	"17|hex UINT_MAX lower"
	"18|hex UINT_MAX upper"
	"19|pointer valido"
	"20|pointer NULL"
	"21|percent simples"
	"22|percent no meio"
	"23|todos os tipos"
	"24|caso misto pesado"
	"25|string vazia misturada"
	"26|d d d sem separador"
	"27|hex hex hex sem separador"
	"28|string NULL com string normal"
	"29|char nul sozinho"
	"30|char nul no meio"
	"31|varios percentuais"
	"32|strings vazias"
	"33|varios negativos"
	"34|hex lower upper misturados"
	"35|dois ponteiros validos"
)

for item in "${CASES[@]}"; do
	id="${item%%|*}"
	name="${item#*|}"
	log="$LOG_DIR/case_$id.log"

	./"$TMP_BIN" ft "$id" > "$FT_OUT" 2> "$FT_RET"
	status_ft=$?
	./"$TMP_BIN" orig "$id" > "$ORIG_OUT" 2> "$ORIG_RET"
	status_orig=$?

	echo "=== CASE $id: $name ===" > "$log"
	echo "" >> "$log"

	if [ "$status_ft" -ne 0 ]; then
		echo "💥 CRASH FT : $id - $name"
		echo "FT exit status: $status_ft" >> "$log"
		FALHOU=$((FALHOU + 1))
		continue
	fi

	if [ "$status_orig" -ne 0 ]; then
		echo "💥 CRASH ORIG : $id - $name"
		echo "ORIG exit status: $status_orig" >> "$log"
		FALHOU=$((FALHOU + 1))
		continue
	fi

	if cmp -s "$FT_OUT" "$ORIG_OUT" && cmp -s "$FT_RET" "$ORIG_RET"; then
		echo "✅ PASSOU : $id - $name"
		echo "=== RESULTADO: PASSOU ===" >> "$log"
		PASSOU=$((PASSOU + 1))
	else
		echo "❌ FALHOU : $id - $name"
		echo "=== RESULTADO: FALHOU ===" >> "$log"
		echo "" >> "$log"
		echo "--- FT stdout hex ---" >> "$log"
		xxd "$FT_OUT" >> "$log"
		echo "" >> "$log"
		echo "--- ORIG stdout hex ---" >> "$log"
		xxd "$ORIG_OUT" >> "$log"
		echo "" >> "$log"
		echo "--- FT retorno ---" >> "$log"
		cat "$FT_RET" >> "$log"
		echo "" >> "$log"
		echo "--- ORIG retorno ---" >> "$log"
		cat "$ORIG_RET" >> "$log"
		FALHOU=$((FALHOU + 1))
	fi
done

rm -f "$TMP_MAIN" "$TMP_BIN"
rm -f "$FT_OUT" "$ORIG_OUT" "$FT_RET" "$ORIG_RET"
rm -f *.o
make clean > /dev/null 2>&1

echo "----------------------------------------"
echo "🏁 Testes concluídos!"
echo "   ✅ Passou : $PASSOU"
echo "   ❌ Falhou : $FALHOU"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"

if [ "$FALHOU" -ne 0 ]; then
	exit 1
fi

exit 0