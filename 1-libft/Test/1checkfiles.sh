#!/bin/bash

# ============================================================
# Verificação da libft - Common Core 42 (subject v19.2)
# Confere arquivos obrigatórios, extras e Norminette
# ============================================================

OBRIGATORIOS="libft.h
Makefile
ft_isalpha.c
ft_isdigit.c
ft_isalnum.c
ft_isascii.c
ft_isprint.c
ft_strlen.c
ft_memset.c
ft_bzero.c
ft_memcpy.c
ft_memmove.c
ft_strlcpy.c
ft_strlcat.c
ft_toupper.c
ft_tolower.c
ft_strchr.c
ft_strrchr.c
ft_strncmp.c
ft_memchr.c
ft_memcmp.c
ft_strnstr.c
ft_atoi.c
ft_calloc.c
ft_strdup.c
ft_substr.c
ft_strjoin.c
ft_strtrim.c
ft_split.c
ft_itoa.c
ft_strmapi.c
ft_striteri.c
ft_putchar_fd.c
ft_putstr_fd.c
ft_putendl_fd.c
ft_putnbr_fd.c
ft_lstnew.c
ft_lstadd_front.c
ft_lstsize.c
ft_lstlast.c
ft_lstadd_back.c
ft_lstdelone.c
ft_lstclear.c
ft_lstiter.c
ft_lstmap.c"

OK=0
ERRO=0
FALTA=0
EXTRA=0

echo "🔍 Verificando libft..."
echo "----------------------------------------"

# 1. Checa cada arquivo da lista oficial
echo "📋 Arquivos obrigatórios:"
for arq in $OBRIGATORIOS; do
    if [ ! -f "$arq" ]; then
        echo "❌ FALTANDO : $arq"
        FALTA=$((FALTA + 1))
    elif [ "$arq" = "Makefile" ]; then
        echo "📝 PRESENTE : $arq (sem Norminette)"
    else
        saida=$(norminette "$arq" 2>&1)
        if echo "$saida" | grep -q "OK!"; then
            echo "✅ NORM OK  : $arq"
            OK=$((OK + 1))
        else
            echo "❌ NORM ERR : $arq"
            echo "$saida" | grep -E "Error|Notice" | sed 's/^/     /'
            ERRO=$((ERRO + 1))
        fi
    fi
done

# 2. Detecta arquivos .c extras (não pertencem ao projeto)
echo ""
echo "🔎 Arquivos .c que não pertencem ao projeto:"
for arq in *.c; do
    if [ ! -f "$arq" ]; then
        continue
    fi
    if ! echo "$OBRIGATORIOS" | grep -qx "$arq"; then
        echo "⚠️  EXTRA   : $arq"
        EXTRA=$((EXTRA + 1))
    fi
done
if [ $EXTRA -eq 0 ]; then
    echo "   (nenhum)"
fi

# 3. Resumo final
echo "----------------------------------------"
echo "🏁 Checagem concluída!"
echo "   Norm OK    : $OK"
echo "   Norm Erro  : $ERRO"
echo "   Faltando   : $FALTA"
echo "   Extras     : $EXTRA"

# Lista de arquivos permitidos no repositório
# (deve conter todos os obrigatórios + README.md)
PERMITIDOS="$OBRIGATORIOS
README.md"

# 1. Checa se o README.md existe
echo ""
echo "📖 Verificando README.md:"
if [ ! -f "README.md" ]; then
    echo "❌ FALTANDO : README.md"
    FALTA=$((FALTA + 1))
else
    echo "✅ PRESENTE : README.md"
fi

# 2. Detecta QUALQUER arquivo que não pertença ao projeto
echo ""
echo "🔎 Arquivos não permitidos no repositório:"
for arq in *; do
    if [ ! -f "$arq" ]; then
        continue
    fi
    if ! echo "$PERMITIDOS" | grep -qx "$arq"; then
        echo "⚠️  EXTRA   : $arq"
        EXTRA=$((EXTRA + 1))
    fi
done
if [ $EXTRA -eq 0 ]; then
    echo "   (nenhum)"
fi