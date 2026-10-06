import Foundation

struct ConnectFourBoard {
    static let rowCount = 6
    static let columnCount = 7
    static let empty = "."
    static let players = ["X", "O"]
    static let directions: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

    private(set) var cells: [[String]]
    private(set) var moves: Int

    init() {
        cells = Array(
            repeating: Array(repeating: Self.empty, count: Self.columnCount),
            count: Self.rowCount
        )
        moves = 0
    }

    var currentPlayer: String {
        Self.players[moves % Self.players.count]
    }

    var winner: String? {
        Self.players.first { hasLine($0) }
    }

    var isOver: Bool {
        winner != nil || moves == Self.rowCount * Self.columnCount
    }

    var rowsTopDown: [[String]] {
        cells.reversed()
    }

    func lowestEmptyRow(in column: Int) -> Int? {
        (0..<Self.rowCount).first { cells[$0][column] == Self.empty }
    }

    func isFull(column: Int) -> Bool {
        lowestEmptyRow(in: column) == nil
    }

    mutating func play(column: Int) {
        guard !isOver, !isFull(column: column), let row = lowestEmptyRow(in: column) else {
            return
        }
        cells[row][column] = currentPlayer
        moves += 1
    }

    private func hasLine(_ player: String) -> Bool {
        for row in 0..<Self.rowCount {
            for column in 0..<Self.columnCount {
                for (rowStep, columnStep) in Self.directions {
                    if (1...3).allSatisfy({
                        matches(row + rowStep * $0, column + columnStep * $0, player)
                    }) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private func matches(_ row: Int, _ column: Int, _ player: String) -> Bool {
        row >= 0 && row < Self.rowCount &&
            column >= 0 && column < Self.columnCount &&
            cells[row][column] == player
    }
}
