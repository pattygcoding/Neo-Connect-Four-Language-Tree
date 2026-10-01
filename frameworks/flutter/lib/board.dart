const rows = 6;
const columns = 7;
const empty = '.';
const players = ['X', 'O'];
const directions = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

List<List<String>> createBoard() =>
    List.generate(rows, (_) => List.filled(columns, empty));

String currentPlayer(int moves) => players[moves % players.length];

int lowestEmptyRow(List<List<String>> board, int column) {
  for (var row = 0; row < rows; row++) {
    if (board[row][column] == empty) {
      return row;
    }
  }
  return -1;
}

bool isColumnFull(List<List<String>> board, int column) =>
    lowestEmptyRow(board, column) == -1;

List<List<String>> drop(List<List<String>> board, int column, String player) {
  final row = lowestEmptyRow(board, column);
  if (row == -1) {
    return board;
  }
  final next = board.map((cells) => List<String>.from(cells)).toList();
  next[row][column] = player;
  return next;
}

bool matches(List<List<String>> board, int row, int column, String player) =>
    row >= 0 &&
    row < rows &&
    column >= 0 &&
    column < columns &&
    board[row][column] == player;

String? winner(List<List<String>> board) {
  for (final player in players) {
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        if (board[row][column] != player) {
          continue;
        }
        for (final direction in directions) {
          final rowStep = direction[0];
          final columnStep = direction[1];
          if (matches(board, row + rowStep, column + columnStep, player) &&
              matches(board, row + rowStep * 2, column + columnStep * 2, player) &&
              matches(board, row + rowStep * 3, column + columnStep * 3, player)) {
            return player;
          }
        }
      }
    }
  }
  return null;
}
