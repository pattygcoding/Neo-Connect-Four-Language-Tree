import { computed, ref } from "vue";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "../utils/board";

export function useConnectFour() {
    const board = ref(createBoard());
    const moves = ref(0);

    const columns = Array.from({ length: COLUMNS }, (_, index) => index);
    const champion = computed(() => winner(board.value));
    const over = computed(() => champion.value !== undefined || moves.value === ROWS * COLUMNS);
    const status = computed(() => {
        if (champion.value) {
            return `Player ${champion.value} wins!`;
        }
        if (over.value) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer(moves.value)}, choose a column.`;
    });

    function play(column) {
        if (over.value || isColumnFull(board.value, column)) {
            return;
        }
        board.value = drop(board.value, column, currentPlayer(moves.value));
        moves.value += 1;
    }

    function reset() {
        board.value = createBoard();
        moves.value = 0;
    }

    return { board, over, status, columns, play, reset, isColumnFull };
}
