import { derived, writable } from "svelte/store";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

const initial = { board: createBoard(), moves: 0 };

export const game = writable(initial);

export const columns = Array.from({ length: COLUMNS }, (_, index) => index);
export const board = derived(game, ($game) => $game.board);
export const champion = derived(game, ($game) => winner($game.board));
export const over = derived(
    game,
    ($game) => winner($game.board) !== undefined || $game.moves === ROWS * COLUMNS
);
export const status = derived(game, ($game) => {
    const won = winner($game.board);
    if (won) {
        return `Player ${won} wins!`;
    }
    if ($game.moves === ROWS * COLUMNS) {
        return "It's a tie!";
    }
    return `Player ${currentPlayer($game.moves)}, choose a column.`;
});

export function play(column) {
    game.update(($game) => {
        if (winner($game.board) || isColumnFull($game.board, column)) {
            return $game;
        }
        return {
            board: drop($game.board, column, currentPlayer($game.moves)),
            moves: $game.moves + 1,
        };
    });
}

export function reset() {
    game.set(initial);
}
