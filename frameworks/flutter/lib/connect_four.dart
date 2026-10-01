import 'package:flutter/material.dart';

import 'board.dart';

class ConnectFour extends StatefulWidget {
  const ConnectFour({super.key});

  @override
  State<ConnectFour> createState() => _ConnectFourState();
}

class _ConnectFourState extends State<ConnectFour> {
  List<List<String>> _board = createBoard();
  int _moves = 0;

  String? get _champion => winner(_board);
  bool get _over => _champion != null || _moves == rows * columns;

  String get _status {
    if (_champion != null) {
      return 'Player $_champion wins!';
    }
    if (_over) {
      return "It's a tie!";
    }
    return 'Player ${currentPlayer(_moves)}, choose a column.';
  }

  void _play(int column) {
    if (_over || isColumnFull(_board, column)) {
      return;
    }
    setState(() {
      _board = drop(_board, column, currentPlayer(_moves));
      _moves++;
    });
  }

  void _reset() {
    setState(() {
      _board = createBoard();
      _moves = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Four')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final row in _board.reversed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final cell in row)
                    Text(cell, style: const TextStyle(fontSize: 20)),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var column = 0; column < columns; column++)
                  IconButton(
                    onPressed: _over || isColumnFull(_board, column)
                        ? null
                        : () => _play(column),
                    icon: Text('${column + 1}'),
                  ),
              ],
            ),
            TextButton(onPressed: _reset, child: const Text('New game')),
          ],
        ),
      ),
    );
  }
}
