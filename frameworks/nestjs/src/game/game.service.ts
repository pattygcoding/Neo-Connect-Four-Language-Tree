import { Injectable } from "@nestjs/common";

import {
    Board,
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

export interface GameState {
    cells: Board;
    moves: number;
}

export interface GameView {
    board: Board;
    moves: number;
    columns: number[];
    status: string;
    over: boolean;
}

@Injectable()
export class GameService {
    fromState(state?: GameState): GameState {
        return state ?? { cells: createBoard(), moves: 0 };
    }

    play(state: GameState, column: number): GameState {
        if (column < 1 || column > COLUMNS || isColumnFull(state.cells, column - 1)) {
            return state;
        }
        return {
            cells: drop(state.cells, column - 1, currentPlayer(state.moves)),
            moves: state.moves + 1,
        };
    }

    view(state: GameState): GameView {
        return {
            board: state.cells,
            moves: state.moves,
            columns: Array.from({ length: COLUMNS }, (_, index) => index + 1),
            status: this.status(state),
            over: winner(state.cells) !== null || state.moves === ROWS * COLUMNS,
        };
    }

    private status(state: GameState): string {
        const champion = winner(state.cells);
        if (champion) {
            return `Player ${champion} wins!`;
        }
        return state.moves === ROWS * COLUMNS
            ? "It's a tie!"
            : `Player ${currentPlayer(state.moves)}, choose a column.`;
    }
}
