#!/bin/bash

# ============================================================
# Teste de Norminette do ft_printf
# Verifica arquivos .c e .h do projeto e da libft
# Salva o resultado em logs_norm/norminette.log
# ============================================================

LOG_DIR="logs_norm"
LOG_FILE="$LOG_DIR/norminette.log"
PASSOU=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_FILE"

echo "📏 Rodando Norminette..."
echo "----------------------------------------"

if ! command -v norminette > /dev/null 2>&1; then
	echo "❌ Norminette nao encontrada"
	echo "Instale ou verifique se o comando esta no PATH"
	exit 1
fi

{
	echo "=== NORMINETTE FT_PRINTF ==="
	echo ""

	norminette *.c *.h

	if [ -d "libft" ]; then
		echo ""
		echo "=== NORMINETTE LIBFT ==="
		echo ""
		norminette libft
	fi
} > "$LOG_FILE" 2>&1

if grep -q "Error" "$LOG_FILE"; then
	echo "❌ NORM ERROR"
	echo "Veja: $LOG_FILE"
	PASSOU=0
else
	echo "✅ NORM OK"
	echo "Veja: $LOG_FILE"
	PASSOU=1
fi

echo "----------------------------------------"

if [ "$PASSOU" -eq 1 ]; then
	echo "🏁 Resultado: passou na Norminette"
	exit 0
fi

echo "🏁 Resultado: falhou na Norminette"
exit 1