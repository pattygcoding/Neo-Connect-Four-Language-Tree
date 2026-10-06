import { computed, ref } from "vue";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "../board";

export function useConnectFour() {
    const board = ref(createBoard());
    const moves = ref(0);

    const champion = computed(() => winner(board.value));
    const over = computed(() => Boolean(champion.value) || moves.value === ROWS * COLUMNS);

    const status = computed(() => {
        if (champion.value) {
            return `Player ${champion.value} wins!`;
        }
        if (over.value) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer(moves.value)}, choose a column.`;
    });

    const rows = computed(() => [...board.value].reverse());

    const columns = computed(() =>
        Array.from({ length: COLUMNS }, (_, index) => ({
            index,
            label: index + 1,
            disabled: over.value || isColumnFull(board.value, index),
        })),
    );

    const alertVariant = computed(() =>
        champion.value ? "success" : over.value ? "warning" : "info",
    );

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

    return { board, moves, status, rows, columns, alertVariant, play, reset };
}
