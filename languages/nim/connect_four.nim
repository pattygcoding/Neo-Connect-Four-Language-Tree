import std/strutils

const
    Rows = 6
    Cols = 7
    Empty = '.'

const
    Players = "XO"

const
    Header = "=== Connect Four ===\n" &
        "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

type
    Board = array[Rows, array[Cols, char]]

proc newBoard(): Board =
    for row in 0 ..< Rows:
        for col in 0 ..< Cols:
            result[row][col] = Empty

proc lowestEmptyRow(board: Board, col: int): int =
    for row in 0 ..< Rows:
        if board[row][col] == Empty:
            return row
    return -1

proc hasFour(board: Board, player: char): bool =
    for row in 0 ..< Rows:
        for col in 0 ..< (Cols - 3):
            if board[row][col] == player and board[row][col + 1] == player and
                    board[row][col + 2] == player and
                    board[row][col + 3] == player:
                return true
    for row in 0 ..< (Rows - 3):
        for col in 0 ..< Cols:
            if board[row][col] == player and board[row + 1][col] == player and
                    board[row + 2][col] == player and
                    board[row + 3][col] == player:
                return true
    for row in 0 ..< (Rows - 3):
        for col in 0 ..< (Cols - 3):
            if board[row][col] == player and board[row + 1][col + 1] == player and
                    board[row + 2][col + 2] == player and
                    board[row + 3][col + 3] == player:
                return true
    for row in 3 ..< Rows:
        for col in 0 ..< (Cols - 3):
            if board[row][col] == player and board[row - 1][col + 1] == player and
                    board[row - 2][col + 2] == player and
                    board[row - 3][col + 3] == player:
                return true
    return false

proc printBorder() =
    stdout.write('+')
    for _ in 0 ..< (Cols * 2 - 1):
        stdout.write('-')
    stdout.write("+\n")

proc printBoard(board: Board) =
    stdout.write(' ')
    for col in 1 .. Cols:
        if col > 1:
            stdout.write(' ')
        stdout.write(char(ord('0') + col))
    stdout.write('\n')
    printBorder()
    for row in countdown(Rows - 1, 0):
        stdout.write('|')
        for col in 0 ..< Cols:
            if col > 0:
                stdout.write(' ')
            stdout.write(board[row][col])
        stdout.write("|\n")
    printBorder()

proc isWholeNumber(token: string): bool =
    var start = 0
    if token.len > 0 and (token[0] == '+' or token[0] == '-'):
        start = 1
    if start >= token.len:
        return false
    for index in start ..< token.len:
        if token[index] < '0' or token[index] > '9':
            return false
    return true

proc parseValue(token: string): int64 =
    try:
        return parseBiggestInt(token)
    except ValueError:
        return high(int64)

proc askColumn(board: Board, player: char): int =
    while true:
        stdout.write("Player ", player, ", choose a column (1-7): ")
        stdout.flushFile()
        var line: string
        if not stdin.readLine(line):
            stdout.write("\nInput closed. Goodbye.\n")
            stdout.flushFile()
            return -1
        let token = line.strip()
        var message: string
        if token.len == 0:
            message = "Invalid input: no column entered."
        elif not isWholeNumber(token):
            message = "Invalid input: \"" & token & "\" is not a whole number."
        else:
            let value = parseValue(token)
            if value < 1 or value > int64(Cols):
                message = "Invalid input: \"" & token & "\" is out of range (1-7)."
            elif lowestEmptyRow(board, int(value) - 1) < 0:
                message = "Column " & $value & " is full."
            else:
                return int(value) - 1
        stdout.write("\n", message, "\n")
        stdout.flushFile()

proc main() =
    var board = newBoard()
    stdout.write(Header)
    stdout.write("\n")
    printBoard(board)
    stdout.flushFile()

    var moves = 0
    var playerIndex = 0
    while true:
        let player = Players[playerIndex]
        let column = askColumn(board, player)
        if column < 0:
            return
        board[lowestEmptyRow(board, column)][column] = player
        inc moves
        stdout.write("\n")
        printBoard(board)
        stdout.flushFile()
        if hasFour(board, player):
            stdout.write("Player ", player, " wins!\n")
            stdout.flushFile()
            return
        if moves == Rows * Cols:
            stdout.write("It's a tie!\n")
            stdout.flushFile()
            return
        playerIndex = 1 - playerIndex

main()
