<?php

const ROWS = 6;
const COLS = 7;
const EMPTY_CELL = '.';
const PLAYERS = 'XO';

const HEADER =
    "=== Connect Four ===\n" .
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

function newBoard() {
    $board = array();
    for ($row = 0; $row < ROWS; ++$row) {
        $board[$row] = array_fill(0, COLS, EMPTY_CELL);
    }
    return $board;
}

function lowestEmptyRow($board, $column) {
    for ($row = 0; $row < ROWS; ++$row) {
        if ($board[$row][$column] === EMPTY_CELL) {
            return $row;
        }
    }
    return -1;
}

function hasFour($board, $player) {
    $at = function ($row, $column) use ($board, $player) {
        return $row >= 0 && $row < ROWS && $column >= 0 && $column < COLS
            && $board[$row][$column] === $player;
    };
    $run = function ($row, $column, $rowStep, $columnStep) use ($at) {
        for ($step = 0; $step < 4; ++$step) {
            if (!$at($row + $step * $rowStep, $column + $step * $columnStep)) {
                return false;
            }
        }
        return true;
    };
    for ($row = 0; $row < ROWS; ++$row) {
        for ($column = 0; $column < COLS; ++$column) {
            if ($run($row, $column, 0, 1) || $run($row, $column, 1, 0)
                || $run($row, $column, 1, 1) || $run($row, $column, 1, -1)) {
                return true;
            }
        }
    }
    return false;
}

function printBorder() {
    echo '+', str_repeat('-', COLS * 2 - 1), "+\n";
}

function printBoard($board) {
    echo ' ';
    for ($column = 1; $column <= COLS; ++$column) {
        if ($column > 1) {
            echo ' ';
        }
        echo $column;
    }
    echo "\n";
    printBorder();
    for ($row = ROWS - 1; $row >= 0; --$row) {
        echo '|';
        for ($column = 0; $column < COLS; ++$column) {
            if ($column > 0) {
                echo ' ';
            }
            echo $board[$row][$column];
        }
        echo "|\n";
    }
    printBorder();
}

function isSpace($character) {
    $code = ord($character);
    return $character === ' ' || ($code >= 9 && $code <= 13);
}

function clean($text) {
    $start = 0;
    $end = strlen($text);
    while ($start < $end && isSpace($text[$start])) {
        ++$start;
    }
    while ($end > $start && isSpace($text[$end - 1])) {
        --$end;
    }
    return substr($text, $start, $end - $start);
}

function isWholeNumber($token) {
    $length = strlen($token);
    $start = 0;
    if ($length > 0 && ($token[0] === '+' || $token[0] === '-')) {
        $start = 1;
    }
    if ($start >= $length) {
        return false;
    }
    for ($index = $start; $index < $length; ++$index) {
        if ($token[$index] < '0' || $token[$index] > '9') {
            return false;
        }
    }
    return true;
}

function parseValue($token) {
    $negative = false;
    $start = 0;
    if ($token[0] === '-') {
        $negative = true;
        $start = 1;
    } elseif ($token[0] === '+') {
        $start = 1;
    }
    $value = 0;
    $length = strlen($token);
    for ($index = $start; $index < $length; ++$index) {
        $digit = ord($token[$index]) - ord('0');
        if ($value > intdiv(PHP_INT_MAX - $digit, 10)) {
            return $negative ? PHP_INT_MIN : PHP_INT_MAX;
        }
        $value = $value * 10 + $digit;
    }
    return $negative ? -$value : $value;
}

function askColumn($board, $player) {
    while (true) {
        echo 'Player ', $player, ', choose a column (1-7): ';
        flush();
        $line = fgets(STDIN);
        if ($line === false) {
            echo "\nInput closed. Goodbye.\n";
            flush();
            return -1;
        }
        $token = clean($line);
        if ($token === '') {
            echo "\nInvalid input: no column entered.\n";
        } elseif (!isWholeNumber($token)) {
            echo "\nInvalid input: \"", $token, "\" is not a whole number.\n";
        } else {
            $value = parseValue($token);
            if ($value < 1 || $value > COLS) {
                echo "\nInvalid input: \"", $token, "\" is out of range (1-7).\n";
            } elseif (lowestEmptyRow($board, $value - 1) < 0) {
                echo "\nColumn ", $value, " is full.\n";
            } else {
                return $value - 1;
            }
        }
        flush();
    }
}

$board = newBoard();
echo HEADER, "\n";
printBoard($board);
flush();

$moves = 0;
$playerIndex = 0;
while (true) {
    $player = PLAYERS[$playerIndex];
    $column = askColumn($board, $player);
    if ($column < 0) {
        break;
    }
    $board[lowestEmptyRow($board, $column)][$column] = $player;
    ++$moves;
    echo "\n";
    printBoard($board);
    flush();
    if (hasFour($board, $player)) {
        echo 'Player ', $player, " wins!\n";
        flush();
        break;
    }
    if ($moves === ROWS * COLS) {
        echo "It's a tie!\n";
        flush();
        break;
    }
    $playerIndex = 1 - $playerIndex;
}
