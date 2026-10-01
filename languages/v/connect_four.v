import os

const rows = 6
const cols = 7
const empty_cell = '.'
const max_value = i64(9223372036854775807)
const header = '=== Connect Four ==='
const rules = 'Get four of your pieces in a row to win. Columns are numbered 1-7.'

fn new_board() [][]string {
    mut board := [][]string{len: rows}
    for row in 0 .. rows {
        board[row] = []string{len: cols, init: empty_cell}
    }
    return board
}

fn lowest_empty_row(board [][]string, column int) int {
    for row in 0 .. rows {
        if board[row][column] == empty_cell {
            return row
        }
    }
    return -1
}

fn run_matches(board [][]string, player string, start_row int, start_column int, row_step int, column_step int) bool {
    for step in 0 .. 4 {
        row := start_row + step * row_step
        column := start_column + step * column_step
        if row < 0 || row >= rows || column < 0 || column >= cols {
            return false
        }
        if board[row][column] != player {
            return false
        }
    }
    return true
}

fn has_four(board [][]string, player string) bool {
    for row in 0 .. rows {
        for column in 0 .. cols {
            if run_matches(board, player, row, column, 0, 1)
                || run_matches(board, player, row, column, 1, 0)
                || run_matches(board, player, row, column, 1, 1)
                || run_matches(board, player, row, column, 1, -1) {
                return true
            }
        }
    }
    return false
}

fn border() string {
    return '+' + '-'.repeat(cols * 2 - 1) + '+'
}

fn render(board [][]string) string {
    mut labels := []string{}
    for column in 1 .. cols + 1 {
        labels << '${column}'
    }
    mut lines := []string{}
    lines << ' ' + labels.join(' ')
    lines << border()
    for row := rows - 1; row >= 0; row-- {
        lines << '|' + board[row].join(' ') + '|'
    }
    lines << border()
    return lines.join('\n')
}

fn is_whole_number(text string) bool {
    body := if text.starts_with('+') || text.starts_with('-') { text[1..] } else { text }
    if body.len == 0 {
        return false
    }
    for index in 0 .. body.len {
        ch := body[index]
        if ch < u8(`0`) || ch > u8(`9`) {
            return false
        }
    }
    return true
}

fn parse_value(text string) i64 {
    mut body := text
    mut negative := false
    if body.starts_with('-') {
        negative = true
        body = body[1..]
    } else if body.starts_with('+') {
        body = body[1..]
    }
    mut value := i64(0)
    for index in 0 .. body.len {
        digit := i64(body[index] - u8(`0`))
        if value > (max_value - digit) / 10 {
            value = max_value
            break
        }
        value = value * 10 + digit
    }
    if negative {
        return -value
    }
    return value
}

fn ask_column(board [][]string, player string) int {
    for {
        line := os.input_opt('Player ${player}, choose a column (1-7): ') or {
            println('\nInput closed. Goodbye.')
            return -1
        }
        token := line.trim_space()
        if token.len == 0 {
            println('\nInvalid input: no column entered.')
        } else if !is_whole_number(token) {
            println('\nInvalid input: "${token}" is not a whole number.')
        } else {
            value := parse_value(token)
            if value < 1 || value > cols {
                println('\nInvalid input: "${token}" is out of range (1-7).')
            } else if lowest_empty_row(board, int(value) - 1) < 0 {
                println('\nColumn ${value} is full.')
            } else {
                return int(value) - 1
            }
        }
    }
    return -1
}

fn main() {
    mut board := new_board()
    players := ['X', 'O']
    println(header)
    println(rules)
    println('')
    print(render(board) + '\n')
    mut player_index := 0
    mut moves := 0
    for {
        player := players[player_index]
        column := ask_column(board, player)
        if column < 0 {
            break
        }
        row := lowest_empty_row(board, column)
        board[row][column] = player
        moves++
        println('')
        print(render(board) + '\n')
        if has_four(board, player) {
            println('Player ${player} wins!')
            break
        }
        if moves == rows * cols {
            println("It's a tie!")
            break
        }
        player_index = 1 - player_index
    }
}
