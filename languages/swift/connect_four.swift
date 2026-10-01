import ucrt

let rows = 6
let cols = 7
let empty: Character = "."
let players: [Character] = ["X", "O"]

let header = "=== Connect Four ===\n"
    + "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

func newBoard() -> [[Character]] {
    Array(repeating: Array(repeating: empty, count: cols), count: rows)
}

func lowestEmptyRow(_ board: [[Character]], _ column: Int) -> Int {
    for row in 0..<rows {
        if board[row][column] == empty {
            return row
        }
    }
    return -1
}

func hasFour(_ board: [[Character]], _ player: Character) -> Bool {
    func at(_ row: Int, _ column: Int) -> Bool {
        row >= 0 && row < rows && column >= 0 && column < cols
            && board[row][column] == player
    }
    for row in 0..<rows {
        for column in 0..<cols {
            if at(row, column)
                && (at(row, column + 1) && at(row, column + 2) && at(row, column + 3)
                    || at(row + 1, column) && at(row + 2, column) && at(row + 3, column)
                    || at(row + 1, column + 1) && at(row + 2, column + 2)
                        && at(row + 3, column + 3)
                    || at(row + 1, column - 1) && at(row + 2, column - 2)
                        && at(row + 3, column - 3)
                )
            {
                return true
            }
        }
    }
    return false
}

func write(_ text: String) {
    print(text, terminator: "")
}

func printBorder() {
    write("+" + String(repeating: "-", count: cols * 2 - 1) + "+\n")
}

func printBoard(_ board: [[Character]]) {
    var text = " "
    for column in 1...cols {
        if column > 1 {
            text += " "
        }
        text += String(column)
    }
    write(text + "\n")
    printBorder()
    var row = rows - 1
    while row >= 0 {
        var line = "|"
        for column in 0..<cols {
            if column > 0 {
                line += " "
            }
            line.append(board[row][column])
        }
        write(line + "|\n")
        row -= 1
    }
    printBorder()
}

func isSpace(_ character: Character) -> Bool {
    guard let value = character.asciiValue else {
        return false
    }
    return character == " " || (value >= 9 && value <= 13)
}

func clean(_ text: String) -> String {
    let characters = Array(text)
    var start = 0
    var end = characters.count
    while start < end && isSpace(characters[start]) {
        start += 1
    }
    while end > start && isSpace(characters[end - 1]) {
        end -= 1
    }
    return String(characters[start..<end])
}

func isWholeNumber(_ token: String) -> Bool {
    let characters = Array(token)
    var start = 0
    if !characters.isEmpty && (characters[0] == "+" || characters[0] == "-") {
        start = 1
    }
    if start >= characters.count {
        return false
    }
    for index in start..<characters.count {
        if characters[index] < "0" || characters[index] > "9" {
            return false
        }
    }
    return true
}

func parseValue(_ token: String) -> Int {
    let characters = Array(token)
    var negative = false
    var start = 0
    if characters[0] == "-" {
        negative = true
        start = 1
    } else if characters[0] == "+" {
        start = 1
    }
    var value = 0
    for index in start..<characters.count {
        guard let digit = characters[index].wholeNumberValue else {
            continue
        }
        if value > (Int.max - digit) / 10 {
            return negative ? Int.min : Int.max
        }
        value = value * 10 + digit
    }
    return negative ? -value : value
}

func askColumn(_ board: [[Character]], _ player: Character) -> Int {
    while true {
        write("Player " + String(player) + ", choose a column (1-7): ")
        fflush(nil)
        guard let line = readLine() else {
            write("\nInput closed. Goodbye.\n")
            fflush(nil)
            return -1
        }
        let token = clean(line)
        if token.isEmpty {
            write("\nInvalid input: no column entered.\n")
        } else if !isWholeNumber(token) {
            write("\nInvalid input: \"" + token + "\" is not a whole number.\n")
        } else {
            let value = parseValue(token)
            if value < 1 || value > cols {
                write("\nInvalid input: \"" + token + "\" is out of range (1-7).\n")
            } else if lowestEmptyRow(board, value - 1) < 0 {
                write("\nColumn " + String(value) + " is full.\n")
            } else {
                return value - 1
            }
        }
        fflush(nil)
    }
}

var board = newBoard()
write(header)
write("\n")
printBoard(board)
fflush(nil)

var moves = 0
var playerIndex = 0
var finished = false
while !finished {
    let player = players[playerIndex]
    let column = askColumn(board, player)
    if column < 0 {
        finished = true
    } else {
        let row = lowestEmptyRow(board, column)
        board[row][column] = player
        moves += 1
        write("\n")
        printBoard(board)
        fflush(nil)
        if hasFour(board, player) {
            write("Player " + String(player) + " wins!\n")
            fflush(nil)
            finished = true
        } else if moves == rows * cols {
            write("It's a tie!\n")
            fflush(nil)
            finished = true
        } else {
            playerIndex = 1 - playerIndex
        }
    }
}
