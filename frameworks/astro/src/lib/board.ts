export const ROWS = 6;
export const COLUMNS = 7;
export const EMPTY = ".";
export const PLAYERS = ["X", "O"] as const;

export type Cell = typeof EMPTY | (typeof PLAYERS)[number];
export type Board = Cell[][];

const DIRECTIONS: ReadonlyArray<readonly [number, number]> = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

export function createBoard(): Board {
    return Array.from({ length: ROWS }, () => Array<Cell>(COLUMNS).fill(EMPTY));
}

export function currentPlayer(moves: number): Cell {
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

export function drop(board: Board, column: number, player: Cell): Board {
    const row = lowestEmptyRow(board, column);
    if (row === -1) {
        return board;
    }
    const next = board.map((cells) => [...cells]);
    next[row][column] = player;
    return next;
}

function matches(board: Board, row: number, column: number, player: Cell): boolean {
    return (
        row >= 0 &&
        row < ROWS &&
        column >= 0 &&
        column < COLUMNS &&
        board[row][column] === player
    );
}

export function winner(board: Board): Cell | null {
    for (const player of PLAYERS) {
        for (let row = 0; row < ROWS; row += 1) {
            for (let column = 0; column < COLUMNS; column += 1) {
                for (const [rowStep, columnStep] of DIRECTIONS) {
                    if (
                        [1, 2, 3].every((step) =>
                            matches(
                                board,
                                row + rowStep * step,
                                column + columnStep * step,
                                player,
                            ),
                        )
                    ) {
                        return player;
                    }
                }
            }
        }
    }
    return null;
}
