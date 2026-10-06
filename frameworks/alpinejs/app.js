import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board.js";

document.addEventListener("alpine:init", () => {
    Alpine.data("connectFour", () => ({
        board: createBoard(),
        moves: 0,
        columns: Array.from({ length: COLUMNS }, (_, index) => index),

        get rows() {
            return [...this.board].reverse();
        },

        get over() {
            return Boolean(winner(this.board)) || this.moves === ROWS * COLUMNS;
        },

        get status() {
            const champion = winner(this.board);
            if (champion) {
                return `Player ${champion} wins!`;
            }
            if (this.over) {
                return "It's a tie!";
            }
            return `Player ${currentPlayer(this.moves)}, choose a column.`;
        },

        isColumnFull(column) {
            return isColumnFull(this.board, column);
        },

        play(column) {
            if (this.over || isColumnFull(this.board, column)) {
                return;
            }
            this.board = drop(this.board, column, currentPlayer(this.moves));
            this.moves += 1;
        },

        reset() {
            this.board = createBoard();
            this.moves = 0;
        },
    }));
});
