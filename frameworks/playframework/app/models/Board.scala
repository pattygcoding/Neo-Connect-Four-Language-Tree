package models

object Board {
    val Rows = 6
    val Columns = 7
    val Empty = "."
    val Players = Seq("X", "O")
    val Directions = Seq((0, 1), (1, 0), (1, 1), (1, -1))

    def emptyCells: Vector[Vector[String]] = Vector.fill(Rows, Columns)(Empty)
}

case class ConnectFourBoard(cells: Vector[Vector[String]] = Board.emptyCells, moves: Int = 0) {

    def currentPlayer: String = Board.Players(moves % Board.Players.size)

    def lowestEmptyRow(column: Int): Int =
        (0 until Board.Rows).find(row => cells(row)(column) == Board.Empty).getOrElse(-1)

    def isFull(column: Int): Boolean = lowestEmptyRow(column) == -1

    def drop(column: Int): ConnectFourBoard = {
        val row = lowestEmptyRow(column)
        if (row == -1) {
            this
        } else {
            copy(
                cells = cells.updated(row, cells(row).updated(column, currentPlayer)),
                moves = moves + 1
            )
        }
    }

    def winner: Option[String] = Board.Players.find(hasLine)

    def isOver: Boolean = winner.isDefined || moves == Board.Rows * Board.Columns

    def rowsTopDown: Vector[Vector[String]] = cells.reverse

    private def hasLine(player: String): Boolean =
        (0 until Board.Rows).exists { row =>
            (0 until Board.Columns).exists { column =>
                Board.Directions.exists { case (rowStep, columnStep) =>
                    (1 to 3).forall(step =>
                        matches(row + rowStep * step, column + columnStep * step, player)
                    )
                }
            }
        }

    private def matches(row: Int, column: Int, player: String): Boolean =
        row >= 0 && row < Board.Rows && column >= 0 && column < Board.Columns &&
            cells(row)(column) == player

    def encode: String = cells.map(_.mkString).mkString + ":" + moves
}

object ConnectFourBoard {
    def decode(raw: String): ConnectFourBoard = {
        val parts = raw.split(":", 2)
        val flat = parts.headOption.getOrElse("")
        if (flat.length != Board.Rows * Board.Columns) {
            ConnectFourBoard()
        } else {
            val cells = Vector.tabulate(Board.Rows) { row =>
                Vector.tabulate(Board.Columns) { column =>
                    flat.charAt(row * Board.Columns + column).toString
                }
            }
            ConnectFourBoard(cells, parts.lift(1).flatMap(_.toIntOption).getOrElse(0))
        }
    }
}
