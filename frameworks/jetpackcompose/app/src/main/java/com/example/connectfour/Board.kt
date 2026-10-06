package com.example.connectfour

data class ConnectFourBoard(
    private val cells: List<List<String>> = List(ROWS) { List(COLUMNS) { EMPTY } },
    val moves: Int = 0,
) {
    companion object {
        const val ROWS = 6
        const val COLUMNS = 7
        const val EMPTY = "."
        val PLAYERS = listOf("X", "O")
        private val DIRECTIONS = listOf(0 to 1, 1 to 0, 1 to 1, 1 to -1)
    }

    val currentPlayer: String
        get() = PLAYERS[moves % PLAYERS.size]

    fun rowsTopDown(): List<List<String>> = cells.reversed()

    fun lowestEmptyRow(column: Int): Int =
        (0 until ROWS).firstOrNull { cells[it][column] == EMPTY } ?: -1

    fun isFull(column: Int): Boolean = lowestEmptyRow(column) == -1

    fun drop(column: Int): ConnectFourBoard {
        val row = lowestEmptyRow(column)
        if (row == -1) {
            return this
        }
        val next = cells.mapIndexed { index, values ->
            if (index == row) values.toMutableList().also { it[column] = currentPlayer } else values
        }
        return copy(cells = next, moves = moves + 1)
    }

    val winner: String?
        get() = PLAYERS.firstOrNull { hasLine(it) }

    val isOver: Boolean
        get() = winner != null || moves == ROWS * COLUMNS

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
}
