#!/usr/bin/env bash
# test_norminette.sh - runs norminette on all .c and .h files.
#
# Usage: ./test_norminette.sh [dir]   (default: current directory)

. "$(dirname "$0")/lib.sh"

DIR="${1:-$PROJECT_DIR}"

if ! command -v norminette >/dev/null 2>&1; then
	info "norminette nao instalada. Instale: pip install norminette"
	exit 0
fi

title "Norminette em $DIR (*.c *.h)"

files="$(find "$DIR" -name '*.c' -o -name '*.h' | sort)"
if [ -z "$files" ]; then
	info "nenhum arquivo .c/.h encontrado"
	exit 0
fi

errors=0
while IFS= read -r f; do
	out="$(norminette "$f" 2>&1)"
	if printf "%s" "$out" | grep -q "OK"; then
		pass "$f"
	else
		fail "$f"
		printf "%s\n" "$out" | grep -E "Error|Notice" | sed 's/^/      /'
		errors=$((errors + 1))
	fi
done <<< "$files"

summary
