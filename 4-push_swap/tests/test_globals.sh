#!/usr/bin/env bash
# test_globals.sh - verifica ausencia de variaveis globais.
#
# "Global variables are forbidden." (Common Instructions)
#
# Usa 'nm' para listar simbolos globais graváveis (segmentos B/D/C).
#   B = BSS (dados nao inicializados, escopo global)
#   D = DATA (dados inicializados, escopo global)
#   C = COMMON (nao inicializados, podem ser mesclados pelo linker)
#
# Excluidos automaticamente:
#   - simbolos com prefixo '__' (adicionados pelo runtime/linker)
#   - simbolos classicos do linker (__bss_start, _edata, _end, etc.)
#   - simbolos de libft (prefixo 'ft_')
#
# Usage: ./test_globals.sh

. "$(dirname "$0")/lib.sh"
need_ps_bin

if ! command -v nm >/dev/null 2>&1; then
	info "nm nao disponivel; pulando teste de variaveis globais"
	exit 0
fi

# Filtra simbolos globais graváveis, excluindo os do sistema/linker
_find_globals() {
	local bin="$1"
	nm -g "$bin" 2>/dev/null \
		| grep -E ' [BDC] ' \
		| grep -v ' __' \
		| grep -v 'ft_' \
		| grep -vE '__bss_start|_edata|_end$|__data_start|__TMC_END__|__dso_handle'
}

# ---------------------------------------------------------------------------
title "Variaveis globais em push_swap"
# ---------------------------------------------------------------------------
globals="$(_find_globals "$PS_BIN")"
if [ -z "$globals" ]; then
	pass "nenhuma variavel global encontrada em push_swap"
else
	fail "variaveis globais detectadas em push_swap:"
	printf "%s\n" "$globals" | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
title "Variaveis globais em checker"
# ---------------------------------------------------------------------------
if [ -x "$CHK_BIN" ]; then
	globals_chk="$(_find_globals "$CHK_BIN")"
	if [ -z "$globals_chk" ]; then
		pass "nenhuma variavel global encontrada em checker"
	else
		fail "variaveis globais detectadas em checker:"
		printf "%s\n" "$globals_chk" | sed 's/^/      /'
	fi
else
	info "checker nao compilado; pulando (execute 'make bonus' para compilar)"
fi

# ---------------------------------------------------------------------------
title "Variaveis estaticas de arquivo (escopo local - informativo)"
# ---------------------------------------------------------------------------
# Variaveis 'b'/'d' (lowercase) sao static locais ao arquivo.
# Nao proibidas pelo subject, mas reportadas para ciencia.
statics="$(nm "$PS_BIN" 2>/dev/null \
	| grep -E ' [bd] ' \
	| grep -v ' __' \
	| grep -v 'ft_')"
if [ -z "$statics" ]; then
	info "nenhuma variavel static de arquivo (b/d) em push_swap"
else
	info "static de arquivo encontradas (nao sao globais, apenas informativo):"
	printf "%s\n" "$statics" | sed 's/^/      /'
fi

summary
