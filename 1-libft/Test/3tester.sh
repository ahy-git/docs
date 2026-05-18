#!/bin/bash

# ============================================================
# Mini-Moulinette caseira da libft
# Para cada ft_*.c, usa um teste testscripts/ft_*.txt
# Compila o teste junto com todos os ft_*.c por dependencias
# Compara todas as linhas FT vs ORIG
# ============================================================

LOG_DIR="logs"
TEST_DIR="testscripts"
TMP_MAIN="main_test.c"
TMP_BIN="test_bin"
PASSOU=0
FALHOU=0
SEM_TESTE=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log
rm -f "$TMP_MAIN" "$TMP_BIN"
rm -f *.o

echo "🧪 Rodando testes da libft..."
echo "----------------------------------------"

for src in ft_*.c; do
	if [ ! -f "$src" ]; then
		continue
	fi

	nome=$(basename "$src" .c)
	txt="$TEST_DIR/$nome.txt"
	log="$LOG_DIR/$nome.log"

	if [ ! -f "$txt" ]; then
		echo "⚪ SEM TESTE : $nome"
		SEM_TESTE=$((SEM_TESTE + 1))
		continue
	fi

	cp "$txt" "$TMP_MAIN"

	cc -Wall -Wextra -Werror "$TMP_MAIN" ft_*.c -o "$TMP_BIN" \
		> "$log" 2>&1

	if [ $? -ne 0 ]; then
		echo "❌ COMPILA   : $nome"
		tmp_log=$(cat "$log")
		echo "=== ERRO DE COMPILACAO ===" > "$log"
		echo "$tmp_log" >> "$log"
		FALHOU=$((FALHOU + 1))
		rm -f "$TMP_MAIN" "$TMP_BIN"
		continue
	fi

	./"$TMP_BIN" > "$log" 2>&1
	status_exec=$?

	if [ "$status_exec" -ne 0 ]; then
		echo "💥 CRASH     : $nome"
		echo "" >> "$log"
		echo "=== RESULTADO: CRASH / ERRO DE EXECUCAO ===" >> "$log"
		echo "Exit status: $status_exec" >> "$log"
		FALHOU=$((FALHOU + 1))
		rm -f "$TMP_MAIN" "$TMP_BIN"
		continue
	fi

	raw_ft=$(grep -a "^FT  :" "$log")
	raw_orig=$(grep -a "^ORIG:" "$log")

	if [ -z "$raw_ft" ] || [ -z "$raw_orig" ]; then
		echo "⚠️  FORMATO  : $nome (faltam linhas FT/ORIG)"
		echo "" >> "$log"
		echo "=== RESULTADO: FORMATO INVALIDO ===" >> "$log"
		FALHOU=$((FALHOU + 1))
		rm -f "$TMP_MAIN" "$TMP_BIN"
		continue
	fi

	count_ft=$(echo "$raw_ft" | wc -l)
	count_orig=$(echo "$raw_orig" | wc -l)

	if [ "$count_ft" -ne "$count_orig" ]; then
		echo "⚠️  FORMATO  : $nome (quantidade FT/ORIG diferente)"
		echo "" >> "$log"
		echo "=== RESULTADO: QUANTIDADE DIFERENTE ===" >> "$log"
		echo "FT   linhas: $count_ft" >> "$log"
		echo "ORIG linhas: $count_orig" >> "$log"
		FALHOU=$((FALHOU + 1))
		rm -f "$TMP_MAIN" "$TMP_BIN"
		continue
	fi

	linha_ft=$(echo "$raw_ft" | sed 's/^FT  ://')
	linha_orig=$(echo "$raw_orig" | sed 's/^ORIG://')

	if [ "$linha_ft" = "$linha_orig" ]; then
		echo "✅ PASSOU    : $nome"
		echo "" >> "$log"
		echo "=== RESULTADO: PASSOU ===" >> "$log"
		PASSOU=$((PASSOU + 1))
	else
		echo "❌ FALHOU    : $nome"
		echo "" >> "$log"
		echo "=== RESULTADO: FALHOU ===" >> "$log"
		echo "$raw_ft" >> "$log"
		echo "$raw_orig" >> "$log"
		FALHOU=$((FALHOU + 1))
	fi

	rm -f "$TMP_MAIN" "$TMP_BIN"
done

rm -f "$TMP_MAIN" "$TMP_BIN"
rm -f *.o

echo "----------------------------------------"
echo "🏁 Testes concluídos!"
echo "   ✅ Passou     : $PASSOU"
echo "   ❌ Falhou     : $FALHOU"
echo "   ⚪ Sem teste  : $SEM_TESTE"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"