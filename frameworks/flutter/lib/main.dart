import 'package:flutter/material.dart';

import 'connect_four.dart';

void main() => runApp(const ConnectFourApp());

class ConnectFourApp extends StatelessWidget {
  const ConnectFourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Connect Four',
      home: ConnectFour(),
    );
  }
}
