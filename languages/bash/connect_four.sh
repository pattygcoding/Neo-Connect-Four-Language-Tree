#!/usr/bin/env bash

set -euo pipefail

ROWS=6
COLS=7
EMPTY='.'
PLAYERS=('X' 'O')
MAX_VALUE=9223372036854775807
MAX_DIV_10=$((MAX_VALUE / 10))
HEADER='=== Connect Four ===
Get four of your pieces in a row to win. Columns are numbered 1-7.'
CHOSEN_COLUMN=-1

DASHES=''
for (( index = 0; index < COLS * 2 - 1; index++ )); do
    DASHES+='-'
done
BORDER="+${DASHES}+"

LABELS=''
for (( index = 1; index <= COLS; index++ )); do
    LABELS+=" $index"
done

declare -a BOARD=()

new_board() {
    local index
    for (( index = 0; index < ROWS * COLS; index++ )); do
        BOARD[$index]=$EMPTY
    done
}

lowest_empty_row() {
    local column=$1 row
    for (( row = 0; row < ROWS; row++ )); do
        if [[ ${BOARD[$((row * COLS + column))]} == "$EMPTY" ]]; then
            printf '%s' "$row"
            return 0
        fi
    done
    printf '%s' -1
}

run_matches() {
    local player=$1 start_row=$2 start_column=$3 row_step=$4 column_step=$5
    local step row column
    for (( step = 0; step < 4; step++ )); do
        row=$((start_row + step * row_step))
        column=$((start_column + step * column_step))
        if (( row < 0 || row >= ROWS || column < 0 || column >= COLS )); then
            return 1
        fi
        if [[ ${BOARD[$((row * COLS + column))]} != "$player" ]]; then
            return 1
        fi
    done
    return 0
}

has_four() {
    local player=$1 row column
    for (( row = 0; row < ROWS; row++ )); do
        for (( column = 0; column < COLS; column++ )); do
            if run_matches "$player" "$row" "$column" 0 1 ||
                run_matches "$player" "$row" "$column" 1 0 ||
                run_matches "$player" "$row" "$column" 1 1 ||
                run_matches "$player" "$row" "$column" 1 -1; then
                return 0
            fi
        done
    done
    return 1
}

print_board() {
    local row column line
    printf '%s\n' "$LABELS"
    printf '%s\n' "$BORDER"
    for (( row = ROWS - 1; row >= 0; row-- )); do
        line='|'
        for (( column = 0; column < COLS; column++ )); do
            if (( column > 0 )); then
                line+=' '
            fi
            line+="${BOARD[$((row * COLS + column))]}"
        done
        printf '%s\n' "${line}|"
    done
    printf '%s\n' "$BORDER"
}

trim() {
    local text=$1
    text=${text#"${text%%[![:space:]]*}"}
    text=${text%"${text##*[![:space:]]}"}
    printf '%s' "$text"
}

is_whole_number() {
    local body=$1
    case $body in
        +* | -*) body=${body:1} ;;
    esac
    [[ -n $body && $body != *[!0-9]* ]]
}

parse_value() {
    local negative=0 body=$1 index digit
    case $body in
        -*)
            negative=1
            body=${body:1}
            ;;
        +*) body=${body:1} ;;
    esac
    local value=0
    for (( index = 0; index < ${#body}; index++ )); do
        if (( value > MAX_DIV_10 )); then
            value=$MAX_VALUE
            break
        fi
        digit=${body:index:1}
        value=$((value * 10 + digit))
    done
    if (( negative )); then
        printf '%s' "$((-value))"
    else
        printf '%s' "$value"
    fi
}

ask_column() {
    local player=$1 line token value
    CHOSEN_COLUMN=-1
    while true; do
        printf 'Player %s, choose a column (1-7): ' "$player"
        if ! IFS= read -r line; then
            printf '\nInput closed. Goodbye.\n'
            return 0
        fi
        token=$(trim "$line")
        if [[ -z $token ]]; then
            printf '\nInvalid input: no column entered.\n'
            continue
        fi
        if ! is_whole_number "$token"; then
            printf '\nInvalid input: "%s" is not a whole number.\n' "$token"
            continue
        fi
        value=$(parse_value "$token")
        if (( value < 1 || value > COLS )); then
            printf '\nInvalid input: "%s" is out of range (1-7).\n' "$token"
            continue
        fi
        if (( $(lowest_empty_row "$((value - 1))") < 0 )); then
            printf '\nColumn %s is full.\n' "$value"
            continue
        fi
        CHOSEN_COLUMN=$((value - 1))
        return 0
    done
}

new_board
printf '%s\n' "$HEADER"
printf '\n'
print_board
player_index=0
moves=0
while true; do
    player=${PLAYERS[$player_index]}
    ask_column "$player"
    if (( CHOSEN_COLUMN < 0 )); then
        break
    fi
    row=$(lowest_empty_row "$CHOSEN_COLUMN")
    BOARD[$((row * COLS + CHOSEN_COLUMN))]=$player
    moves=$((moves + 1))
    printf '\n'
    print_board
    if has_four "$player"; then
        printf 'Player %s wins!\n' "$player"
        break
    fi
    if (( moves == ROWS * COLS )); then
        printf "It's a tie!\n"
        break
    fi
    player_index=$((1 - player_index))
done
