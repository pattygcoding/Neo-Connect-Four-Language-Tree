import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class connect_four {
    static final int ROWS = 6;
    static final int COLS = 7;
    static final char EMPTY = '.';
    static final char[] PLAYERS = { 'X', 'O' };
    static final String HEADER =
        "=== Connect Four ===\n" +
        "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";
    static final String BORDER = makeBorder();
    static final String LABELS = makeLabels();
    static final BufferedReader READER =
        new BufferedReader(new InputStreamReader(System.in));

    static String makeBorder() {
        StringBuilder b = new StringBuilder();
        b.append('+');
        for (int i = 0; i < COLS * 2 - 1; i++) {
            b.append('-');
        }
        b.append('+');
        return b.toString();
    }

    static String makeLabels() {
        StringBuilder b = new StringBuilder();
        b.append(' ');
        for (int c = 1; c <= COLS; c++) {
            if (c > 1) {
                b.append(' ');
            }
            b.append((char) ('0' + c));
        }
        return b.toString();
    }

    static String render(char[][] board) {
        StringBuilder b = new StringBuilder();
        b.append(LABELS).append('\n');
        b.append(BORDER).append('\n');
        for (int r = ROWS - 1; r >= 0; r--) {
            b.append('|');
            for (int c = 0; c < COLS; c++) {
                if (c > 0) {
                    b.append(' ');
                }
                b.append(board[r][c]);
            }
            b.append("|\n");
        }
        b.append(BORDER);
        return b.toString();
    }

    static int lowestEmptyRow(char[][] board, int col) {
        for (int r = 0; r < ROWS; r++) {
            if (board[r][col] == EMPTY) {
                return r;
            }
        }
        return -1;
    }

    static boolean hasFour(char[][] board, char p) {
        for (int r = 0; r < ROWS; r++) {
            for (int c = 0; c + 3 < COLS; c++) {
                if (board[r][c] == p && board[r][c + 1] == p
                    && board[r][c + 2] == p && board[r][c + 3] == p) {
                    return true;
                }
            }
        }
        for (int r = 0; r + 3 < ROWS; r++) {
            for (int c = 0; c < COLS; c++) {
                if (board[r][c] == p && board[r + 1][c] == p
                    && board[r + 2][c] == p && board[r + 3][c] == p) {
                    return true;
                }
            }
        }
        for (int r = 0; r + 3 < ROWS; r++) {
            for (int c = 0; c + 3 < COLS; c++) {
                if (board[r][c] == p && board[r + 1][c + 1] == p
                    && board[r + 2][c + 2] == p && board[r + 3][c + 3] == p) {
                    return true;
                }
            }
        }
        for (int r = 3; r < ROWS; r++) {
            for (int c = 0; c + 3 < COLS; c++) {
                if (board[r][c] == p && board[r - 1][c + 1] == p
                    && board[r - 2][c + 2] == p && board[r - 3][c + 3] == p) {
                    return true;
                }
            }
        }
        return false;
    }

    static boolean isWholeNumber(String token) {
        String t = token;
        if (t.startsWith("+") || t.startsWith("-")) {
            t = t.substring(1);
        }
        if (t.isEmpty()) {
            return false;
        }
        for (int i = 0; i < t.length(); i++) {
            char ch = t.charAt(i);
            if (ch < '0' || ch > '9') {
                return false;
            }
        }
        return true;
    }

    static int askColumn(char[][] board, char player) throws IOException {
        while (true) {
            System.out.print("Player " + player + ", choose a column (1-7): ");
            System.out.flush();
            String raw = READER.readLine();
            if (raw == null) {
                System.out.print("\nInput closed. Goodbye.\n");
                return -1;
            }
            String token = raw.trim();
            String message;
            if (token.isEmpty()) {
                message = "Invalid input: no column entered.";
            } else if (!isWholeNumber(token)) {
                message = "Invalid input: \"" + token + "\" is not a whole number.";
            } else {
                long value;
                try {
                    value = Long.parseLong(token);
                } catch (NumberFormatException e) {
                    value = Long.MAX_VALUE;
                }
                if (value < 1 || value > COLS) {
                    message = "Invalid input: \"" + token + "\" is out of range (1-7).";
                } else if (lowestEmptyRow(board, (int) value - 1) < 0) {
                    message = "Column " + value + " is full.";
                } else {
                    return (int) value - 1;
                }
            }
            System.out.print("\n" + message + "\n");
            System.out.flush();
        }
    }

    public static void main(String[] args) throws IOException {
        char[][] board = new char[ROWS][COLS];
        for (int r = 0; r < ROWS; r++) {
            for (int c = 0; c < COLS; c++) {
                board[r][c] = EMPTY;
            }
        }
        System.out.print(HEADER + "\n" + render(board) + "\n");
        System.out.flush();

        int moves = 0;
        int playerIndex = 0;
        while (true) {
            char player = PLAYERS[playerIndex];
            int column = askColumn(board, player);
            if (column < 0) {
                return;
            }
            board[lowestEmptyRow(board, column)][column] = player;
            moves++;
            System.out.print("\n" + render(board) + "\n");
            if (hasFour(board, player)) {
                System.out.print("Player " + player + " wins!\n");
                return;
            }
            if (moves == ROWS * COLS) {
                System.out.print("It's a tie!\n");
                return;
            }
            playerIndex = 1 - playerIndex;
        }
    }
}
