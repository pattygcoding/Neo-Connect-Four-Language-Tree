package com.example.connectfour

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                ConnectFourScreen()
            }
        }
    }
}

@Composable
fun ConnectFourScreen(viewModel: GameViewModel = viewModel()) {
    val game = viewModel.game
    val champion = game.winner

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Connect Four", style = MaterialTheme.typography.headlineMedium)

        Text(
            when {
                champion != null -> "Player $champion wins!"
                game.isOver -> "It's a tie!"
                else -> "Player ${game.currentPlayer}, choose a column."
            }
        )

        game.rowsTopDown().forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                row.forEach { cell ->
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(discColor(cell)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(cell)
                    }
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(ConnectFourBoard.COLUMNS) { column ->
                Button(
                    onClick = { viewModel.play(column) },
                    enabled = !game.isOver && !game.isFull(column),
                ) {
                    Text("${column + 1}")
                }
            }
        }

        TextButton(onClick = viewModel::reset) {
            Text("New game")
        }
    }
}

private fun discColor(cell: String): Color = when (cell) {
    "X" -> Color(0xFFE53935)
    "O" -> Color(0xFFFDD835)
    else -> Color(0xFF263238)
}
