export const ROWS = 6;
export const COLUMNS = 7;
export const EMPTY = "." as const;
export const PLAYERS = ["X", "O"] as const;

export type Player = (typeof PLAYERS)[number];
export type Cell = Player | typeof EMPTY;
export type Board = Cell[][];

export interface Game {
    cells: Board;
    moves: number;
}

const DIRECTIONS: ReadonlyArray<readonly [number, number]> = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

export function createBoard(): Board {
    return Array.from({ length: ROWS }, () => Array<Cell>(COLUMNS).fill(EMPTY));
}

export function currentPlayer(moves: number): Player {
    return PLAYERS[moves % PLAYERS.length];
}

export function lowestEmptyRow(board: Board, column: number): number {
    for (let row = 0; row < ROWS; row += 1) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

export function isColumnFull(board: Board, column: number): boolean {
    return lowestEmptyRow(board, column) === -1;
}

export function drop(board: Board, column: number, player: Player): Board {
    const row = lowestEmptyRow(board, column);
    if (row === -1) {
        return board;
    }
    return board.map((cells, index) =>
        index === row ? cells.map((cell, position) => (position === column ? player : cell)) : cells
    );
}

function matches(board: Board, row: number, column: number, player: Player): boolean {
    return (
        row >= 0 &&
        row < ROWS &&
        column >= 0 &&
        column < COLUMNS &&
        board[row][column] === player
    );
}

export function winner(board: Board): Player | undefined {
    return PLAYERS.find((player) =>
        board.some((cells, row) =>
            cells.some(
                (cell, column) =>
                    cell === player &&
                    DIRECTIONS.some(
                        ([rowStep, columnStep]) =>
                            matches(board, row + rowStep, column + columnStep, player) &&
                            matches(board, row + rowStep * 2, column + columnStep * 2, player) &&
                            matches(board, row + rowStep * 3, column + columnStep * 3, player)
                    )
            )
        )
    );
}
