#!/bin/bash

# ==============================================================================
# Final and reliable test script for Push_swap (Version 3)
# ==============================================================================
# This script has been fixed to correctly handle the "no arguments" case and
# the sometimes newline-less output from the official checker.
# ==============================================================================

# --- CONFIGURATION ---
PUSH_SWAP="./push_swap"
CHECKER="./checker_linux"

# --- COLORS ---
GREEN="\033[0;32m"; RED="\033[0;31m"; BLUE="\033[0;34m"; NC="\033[0m"
TEST_COUNT=0
FAIL_COUNT=0

# --- FILE CHECK ---
if [ ! -f "$PUSH_SWAP" ] || [ ! -f "$CHECKER" ]; then
    echo -e "${RED}Error: Make sure the '$PUSH_SWAP' and '$CHECKER' executables are present.${NC}"
    exit 1
fi

# --- TEST FUNCTIONS ---

# For cases that must produce an "Error\n"
test_error_case() {
    ((TEST_COUNT++)); DESC=$1; ARG_STR=$2; eval "set -- $ARG_STR"; ARGS=("$@")
    printf "Test %-3d: %-45s" $TEST_COUNT "$DESC"
    
    RESULT=$($PUSH_SWAP "${ARGS[@]}" 2>&1)
    
    if [[ "$(echo -n "$RESULT")" == "Error" ]]; then
        printf "${GREEN}[OK]${NC}\n"
    else
        printf "${RED}[KO]${NC}\n"; ((FAIL_COUNT++))
        echo -n "      -> Expected: 'Error' or 'Error\\n' | Got: "
        echo -n "'$RESULT'" | cat -e
    fi
}

# For cases that must be sorted and validated by the checker
test_valid_case() {
    ((TEST_COUNT++)); DESC=$1; ARG_STR=$2; eval "set -- $ARG_STR"; ARGS=("$@")
    printf "Test %-3d: %-45s" $TEST_COUNT "$DESC"

    # Special case for "no arguments"
    if [ -z "$ARG_STR" ]; then
        RESULT=$($PUSH_SWAP)
        if [ -z "$RESULT" ]; then
            printf "${GREEN}[OK]${NC} (no output)\n"
        else
            printf "${RED}[KO]${NC}\n"; ((FAIL_COUNT++))
            echo -n "      -> Expected: No output | Got: "
            echo -n "'$RESULT'" | cat -e
        fi
        return
    fi

    RESULT=$($PUSH_SWAP "${ARGS[@]}" | $CHECKER "${ARGS[@]}" 2>&1)
    
    if [[ "$(echo -n "$RESULT")" == "OK" ]]; then
        MOVES=$($PUSH_SWAP "${ARGS[@]}" | wc -l | tr -d ' ')
        printf "${GREEN}[OK]${NC} (%s instructions)\n" "$MOVES"
    else
        printf "${RED}[KO]${NC}\n"; ((FAIL_COUNT++))
        echo -n "      -> Expected: 'OK' | Got: "
        echo -n "'$RESULT'" | cat -e
    fi
}

echo -e "${BLUE}Running compliance tests...${NC}"

# === Section 1: Error Handling Tests ===
echo -e "\n## Section 1: Error Handling"
test_error_case "Empty string" '""'
test_error_case "String of spaces" '"   "'
test_error_case "Letters" "1 2a 3"
test_error_case "Duplicates" "1 2 1"
test_error_case "INT_MAX overflow" "2147483648"

# === Section 2: Validity Tests ===
echo -e "\n## Section 2: Valid Cases"
test_valid_case "No arguments" ""
test_valid_case "Already sorted" "1 2 3 4"
test_valid_case "Spaces around (single arg)" '" 1 3 2 "'
test_valid_case "Spaces around (multiple args)" "1 ' 3 ' 2"
test_valid_case "5 numbers" "4 2 5 1 3"
test_valid_case "100 numbers" "\"$(seq 1 100 | sort -R | tr '\n' ' ')\""

# --- SUMMARY ---
echo -e "\n-----------------------------------------------------"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ All ${TEST_COUNT} tests passed!${NC}"
else
    echo -e "${RED}❌ ${FAIL_COUNT} / ${TEST_COUNT} tests failed.${NC}"
fi

