import SwiftUI

struct ContentView: View {
    @State private var board = ConnectFourBoard()

    private var status: String {
        if let champion = board.winner {
            return "Player \(champion) wins!"
        }
        if board.isOver {
            return "It's a tie!"
        }
        return "Player \(board.currentPlayer), choose a column."
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Connect Four")
                .font(.largeTitle)
                .bold()

            Text(status)

            VStack(spacing: 4) {
                ForEach(Array(board.rowsTopDown.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 4) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Circle()
                                .fill(color(for: cell))
                                .frame(width: 40, height: 40)
                                .overlay(Text(cell))
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                ForEach(0..<ConnectFourBoard.columnCount, id: \.self) { column in
                    Button("\(column + 1)") {
                        board.play(column: column)
                    }
                    .disabled(board.isOver || board.isFull(column: column))
                }
            }

            Button("New game") {
                board = ConnectFourBoard()
            }
        }
        .padding()
    }

    private func color(for cell: String) -> Color {
        switch cell {
        case "X":
            return .red
        case "O":
            return .yellow
        default:
            return .gray.opacity(0.25)
        }
    }
}

#Preview {
    ContentView()
}
