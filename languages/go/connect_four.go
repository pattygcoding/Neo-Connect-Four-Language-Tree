package main

import (
    "bufio"
    "os"
    "strconv"
    "strings"
)

const (
    rows  = 6
    cols  = 7
    empty = byte('.')
)

var players = [2]byte{'X', 'O'}

const header = "=== Connect Four ===\n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

var border = "+" + strings.Repeat("-", cols*2-1) + "+"
var labelLine = buildLabels()

func buildLabels() string {
    var b strings.Builder
    b.WriteByte(' ')
    for c := 1; c <= cols; c++ {
        if c > 1 {
            b.WriteByte(' ')
        }
        b.WriteByte(byte('0' + c))
    }
    return b.String()
}

func render(board *[rows][cols]byte) string {
    var b strings.Builder
    b.WriteString(labelLine)
    b.WriteByte('\n')
    b.WriteString(border)
    b.WriteByte('\n')
    for r := rows - 1; r >= 0; r-- {
        b.WriteByte('|')
        for c := 0; c < cols; c++ {
            if c > 0 {
                b.WriteByte(' ')
            }
            b.WriteByte(board[r][c])
        }
        b.WriteString("|\n")
    }
    b.WriteString(border)
    return b.String()
}

func lowestEmptyRow(board *[rows][cols]byte, col int) int {
    for r := 0; r < rows; r++ {
        if board[r][col] == empty {
            return r
        }
    }
    return -1
}

func hasFour(board *[rows][cols]byte, p byte) bool {
    at := func(r, c int) bool { return board[r][c] == p }
    for r := 0; r < rows; r++ {
        for c := 0; c+3 < cols; c++ {
            if at(r, c) && at(r, c+1) && at(r, c+2) && at(r, c+3) {
                return true
            }
        }
    }
    for r := 0; r+3 < rows; r++ {
        for c := 0; c < cols; c++ {
            if at(r, c) && at(r+1, c) && at(r+2, c) && at(r+3, c) {
                return true
            }
        }
    }
    for r := 0; r+3 < rows; r++ {
        for c := 0; c+3 < cols; c++ {
            if at(r, c) && at(r+1, c+1) && at(r+2, c+2) && at(r+3, c+3) {
                return true
            }
        }
    }
    for r := 3; r < rows; r++ {
        for c := 0; c+3 < cols; c++ {
            if at(r, c) && at(r-1, c+1) && at(r-2, c+2) && at(r-3, c+3) {
                return true
            }
        }
    }
    return false
}

func isWholeNumber(token string) bool {
    body := token
    if strings.HasPrefix(body, "+") || strings.HasPrefix(body, "-") {
        body = body[1:]
    }
    if body == "" {
        return false
    }
    for i := 0; i < len(body); i++ {
        if body[i] < '0' || body[i] > '9' {
            return false
        }
    }
    return true
}

var reader = bufio.NewReader(os.Stdin)

// readLine returns the next line (newline stripped) and true, or "" and
// false at end of input.
func readLine() (string, bool) {
    line, err := reader.ReadString('\n')
    if err != nil && line == "" {
        return "", false
    }
    return line, true
}

func askColumn(board *[rows][cols]byte, player byte) int {
    for {
        os.Stdout.WriteString("Player " + string(player) + ", choose a column (1-7): ")
        line, ok := readLine()
        if !ok {
            os.Stdout.WriteString("\nInput closed. Goodbye.\n")
            return -1
        }
        token := strings.TrimSpace(line)
        var message string
        if token == "" {
            message = "Invalid input: no column entered."
        } else if !isWholeNumber(token) {
            message = "Invalid input: \"" + token + "\" is not a whole number."
        } else {
            value, err := strconv.Atoi(token)
            if err != nil || value < 1 || value > cols {
                message = "Invalid input: \"" + token + "\" is out of range (1-7)."
            } else if lowestEmptyRow(board, value-1) < 0 {
                message = "Column " + strconv.Itoa(value) + " is full."
            } else {
                return value - 1
            }
        }
        os.Stdout.WriteString("\n" + message + "\n")
    }
}

func main() {
    var board [rows][cols]byte
    for r := 0; r < rows; r++ {
        for c := 0; c < cols; c++ {
            board[r][c] = empty
        }
    }
    os.Stdout.WriteString(header + "\n" + render(&board) + "\n")
    moves := 0
    playerIndex := 0
    for {
        player := players[playerIndex]
        column := askColumn(&board, player)
        if column < 0 {
            return
        }
        board[lowestEmptyRow(&board, column)][column] = player
        moves++
        os.Stdout.WriteString("\n" + render(&board) + "\n")
        if hasFour(&board, player) {
            os.Stdout.WriteString("Player " + string(player) + " wins!\n")
            return
        }
        if moves == rows*cols {
            os.Stdout.WriteString("It's a tie!\n")
            return
        }
        playerIndex = 1 - playerIndex
    }
}
