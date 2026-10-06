import { createSlice } from "@reduxjs/toolkit";

import { COLUMNS, ROWS, createBoard, currentPlayer, drop, isColumnFull, winner } from "../../board";

const initialState = {
    cells: createBoard(),
    moves: 0,
};

const gameSlice = createSlice({
    name: "game",
    initialState,
    reducers: {
        play(state, action) {
            const column = action.payload;
            const over = Boolean(winner(state.cells)) || state.moves === ROWS * COLUMNS;
            if (over || column < 0 || column >= COLUMNS || isColumnFull(state.cells, column)) {
                return;
            }
            state.cells = drop(state.cells, column, currentPlayer(state.moves));
            state.moves += 1;
        },
        reset() {
            return { cells: createBoard(), moves: 0 };
        },
    },
});

export const { play, reset } = gameSlice.actions;

export const selectBoard = (state) => state.game.cells;
export const selectMoves = (state) => state.game.moves;

export const selectOver = (state) =>
    Boolean(winner(state.game.cells)) || state.game.moves === ROWS * COLUMNS;

export const selectStatus = (state) => {
    const champion = winner(state.game.cells);
    if (champion) {
        return `Player ${champion} wins!`;
    }
    if (state.game.moves === ROWS * COLUMNS) {
        return "It's a tie!";
    }
    return `Player ${currentPlayer(state.game.moves)}, choose a column.`;
};

export default gameSlice.reducer;
