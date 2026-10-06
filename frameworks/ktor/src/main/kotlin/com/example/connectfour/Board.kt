package com.example.connectfour

const val ROWS = 6
const val COLUMNS = 7
const val EMPTY = "."

private val PLAYERS = listOf("X", "O")
private val DIRECTIONS = listOf(0 to 1, 1 to 0, 1 to 1, 1 to -1)

class ConnectFourBoard(
    private val cells: MutableList<MutableList<String>> =
        MutableList(ROWS) { MutableList(COLUMNS) { EMPTY } },
    var moves: Int = 0,
) {
    val currentPlayer: String
        get() = PLAYERS[moves % PLAYERS.size]

    val winner: String?
        get() = PLAYERS.firstOrNull { hasLine(it) }

    val isOver: Boolean
        get() = winner != null || moves == ROWS * COLUMNS

    fun lowestEmptyRow(column: Int): Int {
        for (row in 0 until ROWS) {
            if (cells[row][column] == EMPTY) {
                return row
            }
        }
        return -1
    }

    fun isFull(column: Int): Boolean = lowestEmptyRow(column) == -1

    fun drop(column: Int): Boolean {
        val row = lowestEmptyRow(column)
        if (row == -1) {
            return false
        }
        cells[row][column] = currentPlayer
        moves += 1
        return true
    }

    fun rowsTopDown(): List<List<String>> = cells.reversed()

    private fun hasLine(player: String): Boolean {
        for (row in 0 until ROWS) {
            for (column in 0 until COLUMNS) {
                for ((rowStep, columnStep) in DIRECTIONS) {
                    if ((1..3).all { matches(row + rowStep * it, column + columnStep * it, player) }) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun matches(row: Int, column: Int, player: String): Boolean =
        row in 0 until ROWS && column in 0 until COLUMNS && cells[row][column] == player

    fun encode(): String =
        cells.joinToString(";") { row -> row.joinToString(",") } + "|" + moves

    companion object {
        fun decode(raw: String?): ConnectFourBoard {
            if (raw.isNullOrBlank()) {
                return ConnectFourBoard()
            }
            val (boardPart, movesPart) = raw.split("|", limit = 2)
            val cells = boardPart.split(";").map { row -> row.split(",").toMutableList() }.toMutableList()
            return ConnectFourBoard(cells, movesPart.toIntOrNull() ?: 0)
        }
    }
}
