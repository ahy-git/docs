#!/usr/bin/env bash
# lib.sh - shared config, colors and helpers for the push_swap test suite.
# Source this from every test script: . "$(dirname "$0")/lib.sh"

# ---------------------------------------------------------------------------
# Configuration (override via environment variables)
# ---------------------------------------------------------------------------
# PS_BIN     path to the push_swap binary        (default: ../push_swap)
# CHK_BIN    path to the checker binary           (default: ../checker)
# VERIFIER   command used to validate the op list (default: ps_verify.py)
# CHECKER    optional external checker (e.g. ./checker_linux). If set, it is
#            used instead of VERIFIER for correctness checks.
# LOG_FILE   if set, all [PASS]/[FAIL]/[INFO] lines are appended here too
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PS_BIN="${PS_BIN:-$PROJECT_DIR/push_swap}"
CHK_BIN="${CHK_BIN:-$PROJECT_DIR/checker}"
VERIFIER="${VERIFIER:-python3 $SCRIPT_DIR/ps_verify.py}"
CHECKER="${CHECKER:-}"
LOG_FILE="${LOG_FILE:-}"

# Colors
if [ -t 1 ]; then
	C_GREEN="\033[0;32m"
	C_RED="\033[0;31m"
	C_YELLOW="\033[0;33m"
	C_BLUE="\033[0;34m"
	C_BOLD="\033[1m"
	C_RESET="\033[0m"
else
	C_GREEN=""; C_RED=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
fi

PASS_COUNT=0
FAIL_COUNT=0

# ---------------------------------------------------------------------------
# Logging helper: write plain text (no ANSI) to LOG_FILE when it is set
# ---------------------------------------------------------------------------
_log() {
	[ -n "$LOG_FILE" ] && printf "%s\n" "$*" >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
title() {
	printf "\n${C_BOLD}${C_BLUE}=== %s ===${C_RESET}\n" "$1"
	_log ""
	_log "=== $1 ==="
}

pass() {
	PASS_COUNT=$((PASS_COUNT + 1))
	printf "  ${C_GREEN}[PASS]${C_RESET} %s\n" "$1"
	_log "  [PASS] $1"
}

fail() {
	FAIL_COUNT=$((FAIL_COUNT + 1))
	printf "  ${C_RED}[FAIL]${C_RESET} %s\n" "$1"
	_log "  [FAIL] $1"
}

info() {
	printf "  ${C_YELLOW}[INFO]${C_RESET} %s\n" "$1"
	_log "  [INFO] $1"
}

summary() {
	printf "\n${C_BOLD}Resumo:${C_RESET} "
	printf "${C_GREEN}%d passou${C_RESET}, ${C_RED}%d falhou${C_RESET}\n" \
		"$PASS_COUNT" "$FAIL_COUNT"
	_log ""
	_log "Resumo: $PASS_COUNT passou, $FAIL_COUNT falhou"
	[ "$FAIL_COUNT" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Pre-flight: make sure the binary exists
# ---------------------------------------------------------------------------
need_ps_bin() {
	if [ ! -x "$PS_BIN" ]; then
		printf "${C_RED}push_swap nao encontrado em '%s'.${C_RESET}\n" "$PS_BIN"
		printf "Compile o projeto ou defina PS_BIN.\n"
		exit 2
	fi
}

need_chk_bin() {
	if [ ! -x "$CHK_BIN" ]; then
		printf "${C_YELLOW}checker nao encontrado em '%s' (pulando).${C_RESET}\n" \
			"$CHK_BIN"
		return 1
	fi
	return 0
}

# ---------------------------------------------------------------------------
# Random number generation (unique, portable via python3)
# ---------------------------------------------------------------------------
# rand_nums COUNT [LO] [HI] -> space separated unique random ints
rand_nums() {
	local count="$1"
	local lo="${2:--2147483648}"
	local hi="${3:-2147483647}"
	python3 - "$count" "$lo" "$hi" <<'PYEOF'
import random, sys
count, lo, hi = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
pool = range(lo, hi + 1)
print(" ".join(str(x) for x in random.sample(pool, count)))
PYEOF
}

# ---------------------------------------------------------------------------
# Correctness check: run push_swap on ARGS, validate the op stream.
# Echoes "OK" / "KO" / "Error". Uses external CHECKER if provided.
# ---------------------------------------------------------------------------
verify_sort() {
	local ops
	ops="$("$PS_BIN" "$@" 2>/dev/null)"
	if [ -n "$CHECKER" ]; then
		printf "%s" "$ops" | "$CHECKER" "$@" 2>/dev/null
	else
		printf "%s\n" "$ops" | $VERIFIER "$@" 2>/dev/null
	fi
}

# count_ops ARGS... -> number of operations on stdout
count_ops() {
	"$PS_BIN" "$@" 2>/dev/null | grep -c .
}
