#!/bin/bash

# ============================================================
# Teste de memoria da libft com Valgrind
# ============================================================
#
# O que este script faz?
#
# Este script serve para descobrir se alguma funcao da libft esta:
#
# 1. Vazando memoria
#    Leak acontece quando o programa usa malloc/calloc/strdup,
#    mas depois nao libera aquela memoria com free.
#
#    Exemplo simples:
#        char *s = malloc(10);
#        return ;
#
#    Nesse caso, a memoria alocada se perde. O Valgrind acusa isso
#    como "definitely lost".
#
# 2. Acessando memoria invalida
#    Isso acontece quando o programa le ou escreve fora do espaco
#    permitido.
#
#    Exemplos:
#        acessar array fora do limite;
#        usar ponteiro depois de free;
#        chamar funcao com ponteiro NULL sem proteger;
#        escrever alem do tamanho alocado.
#
#    O Valgrind costuma mostrar mensagens como:
#        Invalid read
#        Invalid write
#        Use of uninitialised value
#
# 3. Dando crash durante o teste
#    Se a funcao causar segmentation fault, o script marca como CRASH.
#
#    Exemplo:
#        ft_strmapi("abc", NULL);
#
#    Se a funcao nao protege f == NULL, ela pode tentar chamar uma
#    funcao inexistente e quebrar.
#
# Como o script funciona?
#
# A pasta testscripts/ tem arquivos de teste, por exemplo:
#
#        testscripts/ft_strlen.txt
#        testscripts/ft_calloc.txt
#        testscripts/ft_split.txt
#
# Cada arquivo desses contem um main de teste.
#
# O script faz assim:
#
# 1. Procura cada arquivo ft_*.c da libft.
# 2. Para cada ft_nome.c, procura testscripts/ft_nome.txt.
# 3. Copia esse teste para um arquivo temporario main_test.c.
# 4. Compila main_test.c junto com todos os ft_*.c.
# 5. Roda o binario com Valgrind.
# 6. Salva o resultado em logs_valgrind/ft_nome.log.
#
# Por que compilar todos os ft_*.c juntos?
#
# Porque algumas funcoes da libft usam outras funcoes da propria libft.
#
# Exemplos:
#        ft_calloc pode usar ft_bzero
#        ft_strdup pode usar ft_strlen
#        ft_strjoin pode usar ft_strlen
#        ft_lstmap pode usar ft_lstnew, ft_lstadd_back e ft_lstclear
#
# Se compilasse apenas o arquivo testado, algumas funcoes poderiam falhar
# por "undefined reference".
#
# O que significa cada resultado?
#
# ✅ OK
#    O teste rodou sem erros de memoria e sem leaks importantes.
#
# ⚠️ LEAK
#    O programa terminou, mas ficou memoria alocada sem free.
#
# ❌ ERRO MEM
#    O Valgrind encontrou erro de memoria, como invalid read/write,
#    uso de valor nao inicializado ou leak considerado erro.
#
# 💥 CRASH
#    O programa quebrou durante a execucao.
#
# ❌ COMPILA
#    O teste nem conseguiu compilar.
#
# ⚪ SEM TESTE
#    Existe ft_nome.c, mas nao existe testscripts/ft_nome.txt.
#
# Observacao importante:
#
# O Valgrind analisa o programa inteiro.
# Entao, se o proprio teste esquecer de dar free em algo, o Valgrind
# tambem vai acusar leak.
#
# Por isso, os testscripts tambem precisam ser bem escritos:
#        se chamou ft_split, precisa liberar tudo;
#        se chamou ft_strdup, precisa dar free;
#        se criou lista com malloc, precisa limpar a lista.
#
# ============================================================

TEST_DIR="testscripts"
LOG_DIR="logs_valgrind"
TMP_MAIN="main_test.c"
TMP_BIN="valgrind_bin"
OK=0
LEAK=0
ERRO=0
CRASH=0
SEM_TESTE=0

if ! command -v valgrind > /dev/null 2>&1; then
	echo "❌ valgrind nao encontrado. Instale com: sudo apt install valgrind"
	exit 1
fi

if [ ! -d "$TEST_DIR" ]; then
	echo "❌ Pasta $TEST_DIR/ nao encontrada!"
	exit 1
fi

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log
rm -f "$TMP_MAIN" "$TMP_BIN"

echo "🔬 Rodando valgrind nos .c da libft..."
echo "----------------------------------------"

for src in ft_*.c; do
	if [ ! -f "$src" ]; then
		continue
	fi

	nome=$(basename "$src" .c)
	teste="$TEST_DIR/$nome.txt"
	log="$LOG_DIR/$nome.log"

	if [ ! -f "$teste" ]; then
		echo "⚪ SEM TESTE   : $nome"
		SEM_TESTE=$((SEM_TESTE + 1))
		continue
	fi

	cp "$teste" "$TMP_MAIN"

	cc -Wall -Wextra -Werror -g "$TMP_MAIN" ft_*.c \
		-o "$TMP_BIN" > "$log" 2>&1

	if [ $? -ne 0 ]; then
		echo "❌ COMPILA     : $nome"
		tmp_log=$(cat "$log")
		echo "=== ERRO DE COMPILACAO ===" > "$log"
		echo "$tmp_log" >> "$log"
		ERRO=$((ERRO + 1))
		rm -f "$TMP_MAIN" "$TMP_BIN"
		continue
	fi

	valgrind \
		--leak-check=full \
		--show-leak-kinds=all \
		--errors-for-leak-kinds=definite,indirect,possible \
		--track-origins=yes \
		--error-exitcode=42 \
		--log-file="$log" \
		./"$TMP_BIN" > /dev/null 2>&1

	exit_code=$?

	if [ "$exit_code" -eq 42 ]; then
		echo "❌ ERRO MEM    : $nome"
		grep -E "Invalid|definitely lost|indirectly lost|possibly lost" \
			"$log" | head -5 | sed 's/^/     /'
		ERRO=$((ERRO + 1))
	elif [ "$exit_code" -ne 0 ]; then
		echo "💥 CRASH       : $nome"
		grep -E "Process terminating|Invalid|SIGSEGV|ERROR SUMMARY" \
			"$log" | head -5 | sed 's/^/     /'
		CRASH=$((CRASH + 1))
	elif grep -q "ERROR SUMMARY: 0 errors" "$log" && \
		grep -q "in use at exit: 0 bytes in 0 blocks" "$log"; then
		echo "✅ OK          : $nome"
		OK=$((OK + 1))
	elif grep -q "ERROR SUMMARY: 0 errors" "$log" && \
		grep -q "All heap blocks were freed" "$log"; then
		echo "✅ OK          : $nome"
		OK=$((OK + 1))
	else
		echo "⚠️  LEAK        : $nome"
		grep -E "in use at exit|definitely lost|indirectly lost|possibly lost" \
			"$log" | head -5 | sed 's/^/     /'
		LEAK=$((LEAK + 1))
	fi

	rm -f "$TMP_MAIN" "$TMP_BIN"
done

rm -f "$TMP_MAIN" "$TMP_BIN"

echo "----------------------------------------"
echo "🏁 Valgrind concluido!"
echo "   ✅ Sem leak    : $OK"
echo "   ⚠️  Com leak    : $LEAK"
echo "   ❌ Erro mem    : $ERRO"
echo "   💥 Crash       : $CRASH"
echo "   ⚪ Sem teste   : $SEM_TESTE"
echo ""
echo "📂 Logs em: $LOG_DIR/"