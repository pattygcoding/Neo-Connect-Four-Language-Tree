package com.example.connectfour;

public class ConnectFourBoard {

    public static final int ROWS = 6;
    public static final int COLUMNS = 7;
    public static final String EMPTY = ".";

    private static final String[] PLAYERS = {"X", "O"};
    private static final int[][] DIRECTIONS = {{0, 1}, {1, 0}, {1, 1}, {1, -1}};

    private final String[][] cells = new String[ROWS][COLUMNS];
    private int moves;

    public ConnectFourBoard() {
        for (String[] row : cells) {
            java.util.Arrays.fill(row, EMPTY);
        }
    }

    public String currentPlayer() {
        return PLAYERS[moves % PLAYERS.length];
    }

    public String winner() {
        for (String player : PLAYERS) {
            if (hasLine(player)) {
                return player;
            }
        }
        return null;
    }

    public boolean isOver() {
        return winner() != null || moves == ROWS * COLUMNS;
    }

    public String cell(int row, int column) {
        return cells[row][column];
    }

    public int lowestEmptyRow(int column) {
        for (int row = 0; row < ROWS; row++) {
            if (EMPTY.equals(cells[row][column])) {
                return row;
            }
        }
        return -1;
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

    private boolean hasLine(String player) {
        for (int row = 0; row < ROWS; row++) {
            for (int column = 0; column < COLUMNS; column++) {
                for (int[] direction : DIRECTIONS) {
                    boolean line = true;
                    for (int step = 1; step <= 3; step++) {
                        if (!matches(row + direction[0] * step, column + direction[1] * step, player)) {
                            line = false;
                            break;
                        }
                    }
                    if (line) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean matches(int row, int column, String player) {
        return row >= 0
                && row < ROWS
                && column >= 0
                && column < COLUMNS
                && player.equals(cells[row][column]);
    }
}
