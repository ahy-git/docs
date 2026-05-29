#!/bin/bash

# ============================================================
# Verificador de prototipos da libft
# ============================================================
#
# Este script verifica:
#
# 1. Se a funcao existe em libft.h.
# 2. Se a funcao existe no arquivo .c correspondente.
# 3. Se o prototipo do .h bate com o esperado.
# 4. Se a assinatura do .c bate com o esperado.
#
# Ele tambem compara nome dos parametros.
#
# Exemplo:
#
# void *ft_memcpy(void *dest, const void *src, size_t n);
#
# e diferente de:
#
# void *ft_memcpy(void *dst, const void *src, size_t n);
#
# Em C, o compilador nao liga para o nome do parametro.
# Este script liga porque o objetivo e padronizacao para estudo.
#
# ============================================================

LOG_DIR="logs_prototypes"
LOG="$LOG_DIR/prototypes.log"
OK=0
ERRO=0
FALTA=0

mkdir -p "$LOG_DIR"
rm -f "$LOG"

echo "🔎 Verificando prototipos da libft..."
echo "----------------------------------------"

normalize()
{
	echo "$1" \
		| tr '\n' ' ' \
		| sed 's/[[:space:]]\+/ /g' \
		| sed 's/[[:space:]]*\*/ */g' \
		| sed 's/\*[[:space:]]*/ */g' \
		| sed 's/[[:space:]]*(/(/g' \
		| sed 's/( */(/g' \
		| sed 's/ *)/)/g' \
		| sed 's/ *, */,/g' \
		| sed 's/ *; */;/g' \
		| sed 's/^ *//' \
		| sed 's/ *$//'
}

get_header_proto()
{
	func="$1"

	grep -E "^[[:space:]]*[A-Za-z_][A-Za-z0-9_[:space:]\*]*[[:space:]\*]${func}[[:space:]]*\(" \
		libft.h | head -n 1
}

get_source_proto()
{
	func="$1"
	file="$2"

	start=$(grep -nE "^[[:space:]]*[A-Za-z_][A-Za-z0-9_[:space:]\*]*[[:space:]\*]${func}[[:space:]]*\(" \
		"$file" | head -n 1 | cut -d: -f1)

	if [ -z "$start" ]; then
		return
	fi

	awk -v start="$start" '
		NR >= start {
			line = line " " $0
			if ($0 ~ /\{/)
			{
				sub(/[[:space:]]*\{.*/, ";", line)
				print line
				exit
			}
		}
	' "$file"
}

check_proto()
{
	func="$1"
	expected="$2"
	file="$func.c"

	expected_norm=$(normalize "$expected")

	if [ ! -f "$file" ]; then
		echo "❌ FALTANDO : $file"
		echo "FALTANDO: $file" >> "$LOG"
		FALTA=$((FALTA + 1))
		return
	fi

	header_proto=$(get_header_proto "$func")
	source_proto=$(get_source_proto "$func" "$file")

	if [ -z "$header_proto" ]; then
		echo "❌ HEADER   : $func nao encontrado em libft.h"
		echo "HEADER FALTANDO: $func" >> "$LOG"
		ERRO=$((ERRO + 1))
		return
	fi

	if [ -z "$source_proto" ]; then
		echo "❌ SOURCE   : $func nao encontrado em $file"
		echo "SOURCE FALTANDO: $func em $file" >> "$LOG"
		ERRO=$((ERRO + 1))
		return
	fi

	header_norm=$(normalize "$header_proto")
	source_norm=$(normalize "$source_proto")

	if [ "$header_norm" != "$expected_norm" ]; then
		echo "❌ HEADER   : $func"
		{
			echo ""
			echo "=== HEADER ERRADO: $func ==="
			echo "ESPERADO  : $expected_norm"
			echo "ENCONTRADO: $header_norm"
			echo "ORIGINAL  : $header_proto"
		} >> "$LOG"
		ERRO=$((ERRO + 1))
		return
	fi

	if [ "$source_norm" != "$expected_norm" ]; then
		echo "❌ SOURCE   : $func"
		{
			echo ""
			echo "=== SOURCE ERRADO: $func ==="
			echo "ESPERADO  : $expected_norm"
			echo "ENCONTRADO: $source_norm"
			echo "ORIGINAL  : $source_proto"
		} >> "$LOG"
		ERRO=$((ERRO + 1))
		return
	fi

	echo "✅ OK       : $func"
	OK=$((OK + 1))
}

if [ ! -f "libft.h" ]; then
	echo "❌ libft.h nao encontrado!"
	exit 1
fi

check_proto "ft_isalpha" "int ft_isalpha(int c);"
check_proto "ft_isdigit" "int ft_isdigit(int c);"
check_proto "ft_isalnum" "int ft_isalnum(int c);"
check_proto "ft_isascii" "int ft_isascii(int c);"
check_proto "ft_isprint" "int ft_isprint(int c);"
check_proto "ft_strlen" "size_t ft_strlen(const char *s);"
check_proto "ft_memset" "void *ft_memset(void *s, int c, size_t n);"
check_proto "ft_bzero" "void ft_bzero(void *s, size_t n);"
check_proto "ft_memcpy" "void *ft_memcpy(void *dest, const void *src, size_t n);"
check_proto "ft_memmove" "void *ft_memmove(void *dest, const void *src, size_t n);"
check_proto "ft_strlcpy" "size_t ft_strlcpy(char *dst, const char *src, size_t size);"
check_proto "ft_strlcat" "size_t ft_strlcat(char *dst, const char *src, size_t size);"
check_proto "ft_toupper" "int ft_toupper(int c);"
check_proto "ft_tolower" "int ft_tolower(int c);"
check_proto "ft_strchr" "char *ft_strchr(const char *s, int c);"
check_proto "ft_strrchr" "char *ft_strrchr(const char *s, int c);"
check_proto "ft_strncmp" "int ft_strncmp(const char *s1, const char *s2, size_t n);"
check_proto "ft_memchr" "void *ft_memchr(const void *s, int c, size_t n);"
check_proto "ft_memcmp" "int ft_memcmp(const void *s1, const void *s2, size_t n);"
check_proto "ft_strnstr" "char *ft_strnstr(const char *big, const char *little, size_t len);"
check_proto "ft_atoi" "int ft_atoi(const char *nptr);"
check_proto "ft_calloc" "void *ft_calloc(size_t nmemb, size_t size);"
check_proto "ft_strdup" "char *ft_strdup(const char *s);"

check_proto "ft_substr" "char *ft_substr(char const *s, unsigned int start, size_t len);"
check_proto "ft_strjoin" "char *ft_strjoin(char const *s1, char const *s2);"
check_proto "ft_strtrim" "char *ft_strtrim(char const *s1, char const *set);"
check_proto "ft_split" "char **ft_split(char const *s, char c);"
check_proto "ft_itoa" "char *ft_itoa(int n);"
check_proto "ft_strmapi" "char *ft_strmapi(char const *s, char (*f)(unsigned int, char));"
check_proto "ft_striteri" "void ft_striteri(char *s, void (*f)(unsigned int, char *));"
check_proto "ft_putchar_fd" "void ft_putchar_fd(char c, int fd);"
check_proto "ft_putstr_fd" "void ft_putstr_fd(char *s, int fd);"
check_proto "ft_putendl_fd" "void ft_putendl_fd(char *s, int fd);"
check_proto "ft_putnbr_fd" "void ft_putnbr_fd(int n, int fd);"

check_proto "ft_lstnew" "t_list *ft_lstnew(void *content);"
check_proto "ft_lstadd_front" "void ft_lstadd_front(t_list **lst, t_list *new);"
check_proto "ft_lstsize" "int ft_lstsize(t_list *lst);"
check_proto "ft_lstlast" "t_list *ft_lstlast(t_list *lst);"
check_proto "ft_lstadd_back" "void ft_lstadd_back(t_list **lst, t_list *new);"
check_proto "ft_lstdelone" "void ft_lstdelone(t_list *lst, void (*del)(void *));"
check_proto "ft_lstclear" "void ft_lstclear(t_list **lst, void (*del)(void *));"
check_proto "ft_lstiter" "void ft_lstiter(t_list *lst, void (*f)(void *));"
check_proto "ft_lstmap" "t_list *ft_lstmap(t_list *lst, void *(*f)(void *), void (*del)(void *));"

echo "----------------------------------------"
echo "🏁 Verificacao de prototipos concluida!"
echo "   ✅ OK       : $OK"
echo "   ❌ Erro     : $ERRO"
echo "   ❌ Faltando : $FALTA"
echo ""
echo "📂 Log em: $LOG"