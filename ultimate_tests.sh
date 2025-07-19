#!/bin/bash

# ==============================================================================
# Script de test final et fiable pour Push_swap (Version 3)
# ==============================================================================
# Ce script a été corrigé pour gérer correctement le cas "aucun argument" et
# les sorties parfois sans retour à la ligne du checker officiel.
# ==============================================================================

# --- CONFIGURATION ---
PUSH_SWAP="./push_swap"
CHECKER="./checker_linux"

# --- COULEURS ---
GREEN="\033[0;32m"; RED="\033[0;31m"; BLUE="\033[0;34m"; NC="\033[0m"
TEST_COUNT=0
FAIL_COUNT=0

# --- VÉRIFICATION DES FICHIERS ---
if [ ! -f "$PUSH_SWAP" ] || [ ! -f "$CHECKER" ]; then
    echo -e "${RED}Erreur : Assure-toi que les exécutables '$PUSH_SWAP' et '$CHECKER' sont présents.${NC}"
    exit 1
fi

# --- FONCTIONS DE TEST ---

# Pour les cas qui doivent produire une erreur "Error\n"
test_error_case() {
    ((TEST_COUNT++)); DESC=$1; ARG_STR=$2; eval "set -- $ARG_STR"; ARGS=("$@")
    printf "Test %-3d: %-45s" $TEST_COUNT "$DESC"
    
    RESULT=$($PUSH_SWAP "${ARGS[@]}" 2>&1)
    
    if [[ "$(echo -n "$RESULT")" == "Error" ]]; then
        printf "${GREEN}[OK]${NC}\n"
    else
        printf "${RED}[KO]${NC}\n"; ((FAIL_COUNT++))
        echo -n "      -> Attendu : 'Error' ou 'Error\\n' | Reçu : "
        echo -n "'$RESULT'" | cat -e
    fi
}

# Pour les cas qui doivent être triés et validés par le checker
test_valid_case() {
    ((TEST_COUNT++)); DESC=$1; ARG_STR=$2; eval "set -- $ARG_STR"; ARGS=("$@")
    printf "Test %-3d: %-45s" $TEST_COUNT "$DESC"

    # Cas spécial pour "aucun argument"
    if [ -z "$ARG_STR" ]; then
        RESULT=$($PUSH_SWAP)
        if [ -z "$RESULT" ]; then
            printf "${GREEN}[OK]${NC} (aucune sortie)\n"
        else
            printf "${RED}[KO]${NC}\n"; ((FAIL_COUNT++))
            echo -n "      -> Attendu : Aucune sortie | Reçu : "
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
        echo -n "      -> Attendu : 'OK' | Reçu : "
        echo -n "'$RESULT'" | cat -e
    fi
}

echo -e "${BLUE}Lancement des tests de conformité...${NC}"

# === Section 1: Tests d'erreurs ===
echo -e "\n## Section 1: Gestion des erreurs"
test_error_case "Chaîne vide" '""'
test_error_case "Chaîne d'espaces" '"   "'
test_error_case "Lettres" "1 2a 3"
test_error_case "Doublons" "1 2 1"
test_error_case "Dépassement INT_MAX" "2147483648"

# === Section 2: Tests de validité ===
echo -e "\n## Section 2: Gestion des cas valides"
test_valid_case "Aucun argument" ""
test_valid_case "Déjà trié" "1 2 3 4"
test_valid_case "Espaces autour (un seul arg)" '" 1 3 2 "'
test_valid_case "Espaces autour (plusieurs args)" "1 ' 3 ' 2"
test_valid_case "5 nombres" "4 2 5 1 3"
test_valid_case "100 nombres" "\"$(seq 1 100 | sort -R | tr '\n' ' ')\""

# --- RÉSUMÉ ---
echo -e "\n-----------------------------------------------------"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les ${TEST_COUNT} tests ont réussi !${NC}"
else
    echo -e "${RED}❌ ${FAIL_COUNT} / ${TEST_COUNT} tests ont échoué.${NC}"
fi