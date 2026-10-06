package com.example.connectfour

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel

class GameViewModel : ViewModel() {
    var game by mutableStateOf(ConnectFourBoard())
        private set

    fun play(column: Int) {
        if (!game.isOver && !game.isFull(column)) {
            game = game.drop(column)
        }
    }

    fun reset() {
        game = ConnectFourBoard()
    }
}
