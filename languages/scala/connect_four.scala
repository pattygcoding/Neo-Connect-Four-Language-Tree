import scala.io.StdIn

object ConnectFour {
    private val Rows = 6
    private val Cols = 7
    private val Empty = '.'
    private val Players = Array('X', 'O')
    private val Header =
        "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n"

    def main(args: Array[String]): Unit = {
        val board = newBoard()
        print(Header + "\n" + render(board) + "\n")
        Console.flush()
        loop(board, 0, 0)
    }

    private def newBoard(): Array[Array[Char]] = Array.fill(Rows, Cols)(Empty)

    private def render(board: Array[Array[Char]]): String = {
        val labels = " " + (1 to Cols).mkString(" ")
        val border = "+" + ("-" * (Cols * 2 - 1)) + "+"
        val rows = (Rows - 1 to 0 by -1).map(r => "|" + board(r).mkString(" ") + "|")
        (labels +: border +: rows :+ border).mkString("\n")
    }

    private def lowestEmptyRow(board: Array[Array[Char]], col: Int): Int = {
        var row = 0
        var result = -1
        while (row < Rows && result == -1) {
            if (board(row)(col) == Empty) result = row
            row += 1
        }
        result
    }

    private def hasFour(board: Array[Array[Char]], player: Char): Boolean = {
        def at(r: Int, c: Int): Boolean = board(r)(c) == player

        var found = false
        var r = 0
        while (r < Rows) {
            var c = 0
            while (c < Cols - 3) {
                if (at(r, c) && at(r, c + 1) && at(r, c + 2) && at(r, c + 3)) found = true
                c += 1
            }
            r += 1
        }
        r = 0
        while (r < Rows - 3) {
            var c = 0
            while (c < Cols) {
                if (at(r, c) && at(r + 1, c) && at(r + 2, c) && at(r + 3, c)) found = true
                c += 1
            }
            r += 1
        }
        r = 0
        while (r < Rows - 3) {
            var c = 0
            while (c < Cols - 3) {
                if (at(r, c) && at(r + 1, c + 1) && at(r + 2, c + 2) && at(r + 3, c + 3)) found = true
                c += 1
            }
            r += 1
        }
        r = 3
        while (r < Rows) {
            var c = 0
            while (c < Cols - 3) {
                if (at(r, c) && at(r - 1, c + 1) && at(r - 2, c + 2) && at(r - 3, c + 3)) found = true
                c += 1
            }
            r += 1
        }
        found
    }

    private def wholeNumber(token: String): Boolean = {
        val body =
            if (token.startsWith("+") || token.startsWith("-")) token.substring(1) else token
        body.nonEmpty && body.forall(ch => ch >= '0' && ch <= '9')
    }

    private def message(text: String): Unit = {
        print("\n" + text + "\n")
        Console.flush()
    }

    private def validate(board: Array[Array[Char]], token: String): Option[Int] = {
        if (token.isEmpty) {
            message("Invalid input: no column entered.")
            None
        } else if (!wholeNumber(token)) {
            message("Invalid input: \"" + token + "\" is not a whole number.")
            None
        } else {
            val value = BigInt(token)
            if (value < BigInt(1) || value > BigInt(Cols)) {
                message("Invalid input: \"" + token + "\" is out of range (1-7).")
                None
            } else if (lowestEmptyRow(board, value.toInt - 1) == -1) {
                message("Column " + value + " is full.")
                None
            } else {
                Some(value.toInt - 1)
            }
        }
    }

    private def askColumn(board: Array[Array[Char]], player: Char): Option[Int] = {
        print("Player " + player + ", choose a column (1-7): ")
        Console.flush()
        val line = StdIn.readLine()
        if (line == null) {
            print("\nInput closed. Goodbye.\n")
            Console.flush()
            None
        } else {
            validate(board, line.trim) match {
                case Some(column) => Some(column)
                case None => askColumn(board, player)
            }
        }
    }

    private def loop(board: Array[Array[Char]], moves: Int, playerIndex: Int): Unit = {
        val player = Players(playerIndex)
        askColumn(board, player) match {
            case None => ()
            case Some(column) =>
                val row = lowestEmptyRow(board, column)
                board(row)(column) = player
                val newMoves = moves + 1
                print("\n" + render(board) + "\n")
                Console.flush()
                if (hasFour(board, player)) {
                    print("Player " + player + " wins!\n")
                    Console.flush()
                } else if (newMoves == Rows * Cols) {
                    print("It's a tie!\n")
                    Console.flush()
                } else {
                    loop(board, newMoves, 1 - playerIndex)
                }
        }
    }
}
