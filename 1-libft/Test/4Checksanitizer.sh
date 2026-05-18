#!/bin/bash

# ============================================================
# Checks de qualidade para libft
# ============================================================
#
# O que este script faz?
#
# Este script nao substitui a Moulinette, mas ajuda a encontrar
# problemas antes da entrega.
#
# Ele faz tres tipos de verificacao:
#
# 1. Compilacao estrita de cada ft_*.c
#    Aqui cada arquivo da libft e compilado sozinho com varias flags
#    extras alem de -Wall -Wextra -Werror.
#
#    Objetivo:
#    - achar variaveis que escondem outras variaveis;
#    - achar conversoes implicitas perigosas;
#    - achar prototipos ausentes;
#    - achar casts suspeitos;
#    - achar codigo inalcançavel;
#    - forcar um nivel mais rigido que o minimo da 42.
#
#    Importante:
#    Essa etapa testa apenas se cada .c compila bem isoladamente.
#    Ela nao roda a funcao.
#
# 2. Sanitizers
#    Aqui o script pega um teste de testscripts/ft_nome.txt,
#    copia para main_test.c e compila esse main temporario junto
#    com todos os ft_*.c da libft.
#
#    Objetivo:
#    - detectar acesso invalido de memoria;
#    - detectar uso de ponteiro invalido;
#    - detectar undefined behavior;
#    - detectar alguns casos de overflow ou comportamento perigoso;
#    - detectar crash durante execucao.
#
#    Importante:
#    O alvo continua sendo a libft.
#    O arquivo testscripts/ft_nome.txt e usado apenas como main
#    temporario para conseguir chamar a funcao testada.
#
# 3. cppcheck
#    Se o programa cppcheck estiver instalado, ele faz uma analise
#    estatica do codigo.
#
#    Objetivo:
#    - encontrar avisos de estilo;
#    - encontrar possiveis erros logicos;
#    - encontrar codigo inutil;
#    - encontrar problemas portaveis entre sistemas.
#
# Observacao importante:
# Este script pode ser mais rigido que a 42.
# Algumas flags extras podem apontar coisas que a Moulinette nao cobra.
# Use como ferramenta de melhoria, nao como verdade absoluta.
#
# ============================================================

TEST_DIR="testscripts"
LOG_DIR="logs_quality"
TMP_MAIN="main_test.c"
TMP_BIN="quality_bin"

OK_COMPILE=0
ERRO_COMPILE=0
OK_SANITIZE=0
ERRO_SANITIZE=0
CRASH_SANITIZE=0
SEM_TESTE=0

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log
rm -f "$TMP_MAIN" "$TMP_BIN"

echo "🔍 Checks de qualidade da libft..."
echo "----------------------------------------"

# ============================================================
# 1. Compilacao com flags estritas
# ============================================================

echo ""
echo "📋 1. Compilacao com flags estritas:"

for src in ft_*.c; do
	if [ ! -f "$src" ]; then
		continue
	fi

	nome=$(basename "$src" .c)
	log="$LOG_DIR/$nome.compile.log"

	cc -Wall -Wextra -Werror \
		-Wshadow \
		-Wconversion \
		-Wstrict-prototypes \
		-Wmissing-prototypes \
		-Wpedantic \
		-Wunreachable-code \
		-Wcast-align \
		-Wcast-qual \
		-c "$src" -o /dev/null > "$log" 2>&1

	if [ $? -eq 0 ] && [ ! -s "$log" ]; then
		echo "✅ $nome"
		OK_COMPILE=$((OK_COMPILE + 1))
		rm -f "$log"
	else
		echo "❌ $nome (ver $log)"
		ERRO_COMPILE=$((ERRO_COMPILE + 1))
	fi
done

# ============================================================
# 2. Sanitizers
# ============================================================

echo ""
echo "🧪 2. Sanitizers (Address + Undefined Behavior):"

if [ ! -d "$TEST_DIR" ]; then
	echo "   ⚠️  Pasta $TEST_DIR/ nao encontrada, pulando sanitizers"
else
	for src in ft_*.c; do
		if [ ! -f "$src" ]; then
			continue
		fi

		nome=$(basename "$src" .c)
		teste="$TEST_DIR/$nome.txt"
		log="$LOG_DIR/$nome.sanitize.log"

		if [ ! -f "$teste" ]; then
			echo "⚪ SEM TESTE   : $nome"
			SEM_TESTE=$((SEM_TESTE + 1))
			continue
		fi

		cp "$teste" "$TMP_MAIN"

		cc -Wall -Wextra -Werror -g \
			-fsanitize=address,undefined \
			"$TMP_MAIN" ft_*.c -o "$TMP_BIN" > "$log" 2>&1

		if [ $? -ne 0 ]; then
			echo "❌ COMPILA     : $nome (sanitizer)"
			tmp_log=$(cat "$log")
			echo "=== ERRO DE COMPILACAO COM SANITIZER ===" > "$log"
			echo "$tmp_log" >> "$log"
			ERRO_SANITIZE=$((ERRO_SANITIZE + 1))
			rm -f "$TMP_MAIN" "$TMP_BIN"
			continue
		fi

		./"$TMP_BIN" >> "$log" 2>&1
		status_exec=$?

		if [ "$status_exec" -ne 0 ]; then
			echo "💥 CRASH       : $nome"
			grep -E "AddressSanitizer|runtime error|UndefinedBehavior|SEGV" \
				"$log" | head -5 | sed 's/^/     /'
			CRASH_SANITIZE=$((CRASH_SANITIZE + 1))
			rm -f "$TMP_MAIN" "$TMP_BIN"
			continue
		fi

		if grep -qE "runtime error|AddressSanitizer|UndefinedBehavior|UBSan" \
			"$log"; then
			echo "❌ ERRO SAN    : $nome"
			grep -E "runtime error|AddressSanitizer|UndefinedBehavior|UBSan" \
				"$log" | head -5 | sed 's/^/     /'
			ERRO_SANITIZE=$((ERRO_SANITIZE + 1))
		else
			echo "✅ OK          : $nome"
			OK_SANITIZE=$((OK_SANITIZE + 1))
			rm -f "$log"
		fi

		rm -f "$TMP_MAIN" "$TMP_BIN"
	done
fi

# ============================================================
# 3. cppcheck
# ============================================================

echo ""
echo "🔎 3. Analise estatica (cppcheck):"

if command -v cppcheck > /dev/null 2>&1; then
	cppcheck \
		--enable=warning,style,performance,portability \
		--suppress=missingIncludeSystem \
		--quiet ft_*.c 2> "$LOG_DIR/cppcheck.log"

	if [ -s "$LOG_DIR/cppcheck.log" ]; then
		echo "⚠️  Avisos encontrados:"
		head -10 "$LOG_DIR/cppcheck.log" | sed 's/^/     /'
		echo "     (log completo em $LOG_DIR/cppcheck.log)"
	else
		echo "✅ Sem avisos do cppcheck"
		rm -f "$LOG_DIR/cppcheck.log"
	fi
else
	echo "   (cppcheck nao instalado, pulando)"
	echo "   Instale com: sudo apt install cppcheck"
fi

rm -f "$TMP_MAIN" "$TMP_BIN" *.o

echo ""
echo "----------------------------------------"
echo "🏁 Quality checks concluidos!"
echo "   Compilacao estrita : $OK_COMPILE ok, $ERRO_COMPILE erro"
echo "   Sanitizers         : $OK_SANITIZE ok, $ERRO_SANITIZE erro"
echo "   Crash sanitizer    : $CRASH_SANITIZE"
echo "   Sem teste          : $SEM_TESTE"
echo ""
echo "📂 Logs em: $LOG_DIR/"