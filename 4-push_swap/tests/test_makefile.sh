#!/usr/bin/env bash
# test_makefile.sh - verifica regras do Makefile e ausencia de relink.
#
# Checks (Common Instructions):
#   - Regras obrigatorias: NAME/all, clean, fclean, re, bonus
#   - make produz o binario push_swap
#   - Segunda execucao de make nao recompila (sem relink)
#   - make fclean remove push_swap e checker
#   - make re reconstroi push_swap a partir do zero
#   - make bonus compila checker (bonus)
#
# AVISO: este script executa make fclean/re/bonus no projeto.
# Ao final ele garante que push_swap esteja reconstruido.
#
# Usage: ./test_makefile.sh

. "$(dirname "$0")/lib.sh"

MK="$PROJECT_DIR/Makefile"
BIN="$PROJECT_DIR/push_swap"
CHK="$PROJECT_DIR/checker"

# ---------------------------------------------------------------------------
title "Regras obrigatorias presentes no Makefile"
# ---------------------------------------------------------------------------
for rule in all clean fclean re bonus; do
	if grep -qE "^${rule}[[:space:]]*:" "$MK" 2>/dev/null; then
		pass "regra '$rule' encontrada"
	else
		fail "regra '$rule' NAO encontrada em $MK"
	fi
done

# ---------------------------------------------------------------------------
title "Compilacao: make (all)"
# ---------------------------------------------------------------------------
make -C "$PROJECT_DIR" fclean >/dev/null 2>&1
make_out="$(make -C "$PROJECT_DIR" 2>&1)"
make_exit=$?
if [ "$make_exit" -eq 0 ] && [ -x "$BIN" ]; then
	pass "push_swap compilado (exit $make_exit)"
else
	fail "make retornou $make_exit ou binario ausente"
	printf "%s\n" "$make_out" | head -10 | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
title "Sem relink: segunda execucao de make"
# ---------------------------------------------------------------------------
out2="$(make -C "$PROJECT_DIR" 2>&1)"
if printf "%s" "$out2" | grep -qiE "up to date|Nothing to be done"; then
	pass "segunda execucao: nada recompilado"
elif [ -z "$(printf "%s" "$out2" | tr -d '[:space:]')" ]; then
	pass "segunda execucao: sem saida (nenhuma recompilacao)"
else
	fail "segunda execucao recompilou algo:"
	printf "%s\n" "$out2" | head -10 | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
title "make fclean remove os binarios"
# ---------------------------------------------------------------------------
make -C "$PROJECT_DIR" fclean >/dev/null 2>&1
if [ ! -f "$BIN" ]; then
	pass "push_swap removido por fclean"
else
	fail "push_swap ainda existe apos fclean"
fi
if [ ! -f "$CHK" ]; then
	pass "checker removido por fclean (ou nunca existiu)"
else
	fail "checker ainda existe apos fclean"
fi

# ---------------------------------------------------------------------------
title "make re reconstroi push_swap do zero"
# ---------------------------------------------------------------------------
re_out="$(make -C "$PROJECT_DIR" re 2>&1)"
re_exit=$?
if [ "$re_exit" -eq 0 ] && [ -x "$BIN" ]; then
	pass "make re: push_swap reconstruido (exit $re_exit)"
else
	fail "make re: falhou (exit $re_exit) ou binario ausente"
	printf "%s\n" "$re_out" | head -10 | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
title "make bonus compila o checker"
# ---------------------------------------------------------------------------
bonus_out="$(make -C "$PROJECT_DIR" bonus 2>&1)"
bonus_exit=$?
if [ "$bonus_exit" -eq 0 ] && [ -x "$CHK" ]; then
	pass "checker compilado por make bonus"
else
	info "make bonus retornou $bonus_exit ou checker nao gerado (bonus opcional)"
fi

# ---------------------------------------------------------------------------
# Garante que push_swap existe para os testes seguintes
# ---------------------------------------------------------------------------
if [ ! -x "$BIN" ]; then
	make -C "$PROJECT_DIR" >/dev/null 2>&1
fi

summary
