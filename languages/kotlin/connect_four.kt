import java.io.BufferedReader
import java.io.InputStreamReader

private const val ROWS = 6
private const val COLS = 7
private const val EMPTY = '.'
private val PLAYERS = charArrayOf('X', 'O')
private const val HEADER = "=== Connect Four ===\n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

private val BORDER = buildBorder()
private val LABELS = buildLabels()

private fun buildBorder(): String {
    val sb = StringBuilder()
    sb.append('+')
    for (i in 0 until COLS * 2 - 1) {
        sb.append('-')
    }
    sb.append('+')
    return sb.toString()
}

private fun buildLabels(): String {
    val sb = StringBuilder()
    sb.append(' ')
    for (c in 1..COLS) {
        if (c > 1) {
            sb.append(' ')
        }
        sb.append(('0'.code + c).toChar())
    }
    return sb.toString()
}

private fun render(board: Array<CharArray>): String {
    val sb = StringBuilder()
    sb.append(LABELS).append('\n')
    sb.append(BORDER).append('\n')
    for (r in ROWS - 1 downTo 0) {
        sb.append('|')
        for (c in 0 until COLS) {
            if (c > 0) {
                sb.append(' ')
            }
            sb.append(board[r][c])
        }
        sb.append("|\n")
    }
    sb.append(BORDER)
    return sb.toString()
}

private fun lowestEmptyRow(board: Array<CharArray>, col: Int): Int {
    for (r in 0 until ROWS) {
        if (board[r][col] == EMPTY) {
            return r
        }
    }
    return -1
}

private fun hasFour(board: Array<CharArray>, p: Char): Boolean {
    for (r in 0 until ROWS) {
        for (c in 0 until COLS - 3) {
            if (board[r][c] == p && board[r][c + 1] == p &&
                board[r][c + 2] == p && board[r][c + 3] == p
            ) {
                return true
            }
        }
    }
    for (r in 0 until ROWS - 3) {
        for (c in 0 until COLS) {
            if (board[r][c] == p && board[r + 1][c] == p &&
                board[r + 2][c] == p && board[r + 3][c] == p
            ) {
                return true
            }
        }
    }
    for (r in 0 until ROWS - 3) {
        for (c in 0 until COLS - 3) {
            if (board[r][c] == p && board[r + 1][c + 1] == p &&
                board[r + 2][c + 2] == p && board[r + 3][c + 3] == p
            ) {
                return true
            }
        }
    }
    for (r in 3 until ROWS) {
        for (c in 0 until COLS - 3) {
            if (board[r][c] == p && board[r - 1][c + 1] == p &&
                board[r - 2][c + 2] == p && board[r - 3][c + 3] == p
            ) {
                return true
            }
        }
    }
    return false
}

private fun isWholeNumber(token: String): Boolean {
    var t = token
    if (t.startsWith("+") || t.startsWith("-")) {
        t = t.substring(1)
    }
    return t.isNotEmpty() && t.all { it in '0'..'9' }
}

private val reader = BufferedReader(InputStreamReader(System.`in`))

private fun askColumn(board: Array<CharArray>, player: Char): Int {
    while (true) {
        print("Player $player, choose a column (1-7): ")
        System.out.flush()
        val raw = reader.readLine()
        if (raw == null) {
            print("\nInput closed. Goodbye.\n")
            return -1
        }
        val token = raw.trim()
        val message: String
        if (token.isEmpty()) {
            message = "Invalid input: no column entered."
        } else if (!isWholeNumber(token)) {
            message = "Invalid input: \"$token\" is not a whole number."
        } else {
            val value = token.toLongOrNull()
            if (value == null || value < 1 || value > COLS) {
                message = "Invalid input: \"$token\" is out of range (1-7)."
            } else if (lowestEmptyRow(board, value.toInt() - 1) < 0) {
                message = "Column $value is full."
            } else {
                return value.toInt() - 1
            }
        }
        print("\n$message\n")
        System.out.flush()
    }
}

fun main() {
    val board = Array(ROWS) { CharArray(COLS) { EMPTY } }
    print(HEADER + "\n" + render(board) + "\n")
    System.out.flush()

    var moves = 0
    var playerIndex = 0
    while (true) {
        val player = PLAYERS[playerIndex]
        val column = askColumn(board, player)
        if (column < 0) {
            return
        }
        board[lowestEmptyRow(board, column)][column] = player
        moves++
        print("\n" + render(board) + "\n")
        if (hasFour(board, player)) {
            print("Player $player wins!\n")
            return
        }
        if (moves == ROWS * COLS) {
            print("It's a tie!\n")
            return
        }
        playerIndex = 1 - playerIndex
    }
}
