#!/bin/bash

# ============================================================
# Norminette runner
# Checks all .c and .h files in the project root.
# Ignores testscripts/ (not part of the submission).
# ============================================================

LOG_DIR="logs"
PASSOU=0
FALHOU=0
SEM_ARQUIVO=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/norm_*.log

if ! command -v norminette > /dev/null 2>&1; then
	echo "❌ norminette nao encontrada no PATH."
	echo "   Instale com: pip install norminette"
	exit 1
fi

echo "🧪 Rodando Norminette..."
echo "----------------------------------------"

arquivos=$(ls *.c *.h 2> /dev/null)

if [ -z "$arquivos" ]; then
	echo "⚪ Nenhum arquivo .c ou .h na raiz."
	SEM_ARQUIVO=1
	echo "----------------------------------------"
	echo "🏁 Norminette concluida!"
	echo "   ⚪ Sem arquivos: $SEM_ARQUIVO"
	exit 0
fi

for src in $arquivos; do
	nome=$(basename "$src")
	log="$LOG_DIR/norm_$nome.log"

	norminette "$src" > "$log" 2>&1
	status=$?

	if [ "$status" -eq 0 ]; then
		echo "✅ OK         : $nome"
		PASSOU=$((PASSOU + 1))
	else
		echo "❌ ERRO       : $nome"
		FALHOU=$((FALHOU + 1))
	fi
done

echo "----------------------------------------"
echo "🏁 Norminette concluida!"
echo "   ✅ Passou : $PASSOU"
echo "   ❌ Falhou : $FALHOU"
echo ""
echo "📂 Logs salvos em: $LOG_DIR/"