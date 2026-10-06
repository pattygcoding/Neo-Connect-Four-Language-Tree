package com.example.connectfour;

public final class Main {

    private Main() {
    }

    public static void main(String[] args) {
        Board board = new Board();

        // X builds a bottom-row line while O answers in the same columns.
        for (int column : new int[] {0, 0, 1, 1, 2, 2, 3}) {
            board.drop(column);
        }

        System.out.println(board.render());
        System.out.println(board.winner() + " wins!");
    }
}
