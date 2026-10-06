package com.example.connectfour;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class BoardTest {

    @Test
    void startsEmptyWithXToMove() {
        Board board = new Board();
        assertEquals("X", board.currentPlayer());
        assertNull(board.winner());
        assertFalse(board.isOver());
    }

    @Test
    void detectsAHorizontalWin() {
        Board board = new Board();
        for (int column : new int[] {0, 0, 1, 1, 2, 2, 3}) {
            board.drop(column);
        }
        assertEquals("X", board.winner());
        assertTrue(board.isOver());
    }

    @Test
    void detectsAVerticalWin() {
        Board board = new Board();
        for (int column : new int[] {0, 1, 0, 1, 6, 1, 6, 1}) {
            board.drop(column);
        }
        assertEquals("O", board.winner());
    }

    @Test
    void rejectsAFullColumn() {
        Board board = new Board();
        for (int move = 0; move < Board.ROWS; move++) {
            assertTrue(board.drop(0));
        }
        assertTrue(board.isFull(0));
        assertFalse(board.drop(0));
        assertEquals(Board.ROWS, board.moves());
    }
}
