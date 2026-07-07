#!/usr/bin/env bash
# run_all.sh - runs the full push_swap test suite.
#
# Usage: ./run_all.sh
# Env: PS_BIN, CHK_BIN, CHECKER, VERIFIER (see lib.sh)

. "$(dirname "$0")/lib.sh"
need_ps_bin

D="$(dirname "$0")"
FAILED=0

# ---------------------------------------------------------------------------
# Logging: create logs/ directory and set LOG_FILE for all sub-scripts
# ---------------------------------------------------------------------------
LOG_DIR="$D/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/run_$(date +%Y%m%d_%H%M%S).log"
export LOG_FILE

{
	printf "========================================\n"
	printf "push_swap test suite\n"
	printf "Data:    %s\n" "$(date)"
	printf "PS_BIN:  %s\n" "$PS_BIN"
	printf "CHK_BIN: %s\n" "$CHK_BIN"
	printf "========================================\n"
} >> "$LOG_FILE"

printf "\n${C_BOLD}Log salvo em:${C_RESET} %s\n" "$LOG_FILE"

run_stage() {
	local script="$1"
	shift
	printf "\n${C_BOLD}########## %s ##########${C_RESET}\n" "$script"
	_log ""
	_log "########## $script ##########"
	bash "$D/$script" "$@"
	[ $? -ne 0 ] && FAILED=$((FAILED + 1))
}

# --- norma e convencoes ---
run_stage test_norminette.sh
run_stage test_globals.sh
run_stage test_makefile.sh
run_stage test_checker.sh

# --- parsing e formato basico ---
run_stage test_errors.sh
run_stage test_basic.sh

# --- corretude da ordenacao ---
run_stage test_correctness.sh 100 20

# --- flags, --bench e roteamento adaptive ---
run_stage test_flags.sh 100
run_stage test_bench_format.sh
run_stage test_adaptive.sh

# --- comparacao de algoritmos e performance ---
run_stage compare_algos.sh 100
run_stage test_performance.sh 50

# --- estabilidade e memoria ---
run_stage test_stability.sh 500 20 10
run_stage test_leaks.sh 100

printf "\n${C_BOLD}===================================${C_RESET}\n"
if [ "$FAILED" -eq 0 ]; then
	printf "${C_GREEN}${C_BOLD}TODAS AS ETAPAS PASSARAM${C_RESET}\n"
	_log ""
	_log "==================================="
	_log "TODAS AS ETAPAS PASSARAM"
	printf "${C_BOLD}Log:${C_RESET} %s\n" "$LOG_FILE"
	exit 0
else
	printf "${C_RED}${C_BOLD}%d ETAPA(S) COM FALHA${C_RESET}\n" "$FAILED"
	_log ""
	_log "==================================="
	_log "$FAILED ETAPA(S) COM FALHA"
	printf "${C_BOLD}Log:${C_RESET} %s\n" "$LOG_FILE"
	exit 1
fi
