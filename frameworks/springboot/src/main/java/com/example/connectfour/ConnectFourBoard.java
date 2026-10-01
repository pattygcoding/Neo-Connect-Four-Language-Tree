package com.example.connectfour;

import java.util.ArrayList;
import java.util.List;

public class ConnectFourBoard {
    public static final int ROWS = 6;
    public static final int COLUMNS = 7;
    private static final char EMPTY = '.';
    private static final char[] PLAYERS = {'X', 'O'};
    private static final int[][] DIRECTIONS = {{0, 1}, {1, 0}, {1, 1}, {1, -1}};

    private final char[][] cells;
    private int moves;

    public ConnectFourBoard() {
        this.cells = new char[ROWS][COLUMNS];
        for (int row = 0; row < ROWS; row++) {
            for (int column = 0; column < COLUMNS; column++) {
                this.cells[row][column] = EMPTY;
            }
        }
    }

    public char currentPlayer() {
        return PLAYERS[moves % PLAYERS.length];
    }

    public char winner() {
        for (char player : PLAYERS) {
            if (hasLine(player)) {
                return player;
            }
        }
        return EMPTY;
    }

    public boolean isOver() {
        return winner() != EMPTY || moves == ROWS * COLUMNS;
    }

    public boolean isFull(int column) {
        return lowestEmptyRow(column) < 0;
    }

    public boolean drop(int column) {
        int row = lowestEmptyRow(column);
        if (row < 0) {
            return false;
        }
        cells[row][column] = currentPlayer();
        moves++;
        return true;
    }

    public List<Character> row(int row) {
        List<Character> values = new ArrayList<>();
        for (int column = 0; column < COLUMNS; column++) {
            values.add(cells[row][column]);
        }
        return values;
    }

    private int lowestEmptyRow(int column) {
        for (int row = 0; row < ROWS; row++) {
            if (cells[row][column] == EMPTY) {
                return row;
            }
        }
        return -1;
    }

    private boolean hasLine(char player) {
        for (int row = 0; row < ROWS; row++) {
            for (int column = 0; column < COLUMNS; column++) {
                if (cells[row][column] != player) {
                    continue;
                }
                for (int[] direction : DIRECTIONS) {
                    if (matches(row + direction[0], column + direction[1], player)
                            && matches(row + direction[0] * 2, column + direction[1] * 2, player)
                            && matches(row + direction[0] * 3, column + direction[1] * 3, player)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean matches(int row, int column, char player) {
        return row >= 0 && row < ROWS && column >= 0 && column < COLUMNS && cells[row][column] == player;
    }
}
