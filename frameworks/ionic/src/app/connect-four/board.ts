export const ROWS = 6;
export const COLUMNS = 7;
export const EMPTY = ".";
export const PLAYERS = ["X", "O"] as const;

export type Cell = typeof EMPTY | (typeof PLAYERS)[number];

const DIRECTIONS: ReadonlyArray<readonly [number, number]> = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

export class ConnectFourBoard {
    cells: Cell[][] = [];
    moves = 0;

    constructor() {
        this.cells = Array.from({ length: ROWS }, () => Array<Cell>(COLUMNS).fill(EMPTY));
    }

    get currentPlayer(): Cell {
        return PLAYERS[this.moves % PLAYERS.length];
    }

    get winner(): Cell | null {
        for (const player of PLAYERS) {
            if (this.hasLine(player)) {
                return player;
            }
        }
        return null;
    }

    get isOver(): boolean {
        return this.winner !== null || this.moves === ROWS * COLUMNS;
    }

    lowestEmptyRow(column: number): number {
        for (let row = 0; row < ROWS; row += 1) {
            if (this.cells[row][column] === EMPTY) {
                return row;
            }
        }
        return -1;
    }

    isFull(column: number): boolean {
        return this.lowestEmptyRow(column) === -1;
    }

    play(column: number): boolean {
        if (this.isOver || this.isFull(column)) {
            return false;
        }
        const row = this.lowestEmptyRow(column);
        this.cells[row][column] = this.currentPlayer;
        this.moves += 1;
        return true;
    }

    get rowsTopDown(): Cell[][] {
        return [...this.cells].reverse();
    }

    private hasLine(player: Cell): boolean {
        for (let row = 0; row < ROWS; row += 1) {
            for (let column = 0; column < COLUMNS; column += 1) {
                for (const [rowStep, columnStep] of DIRECTIONS) {
                    if (
                        [1, 2, 3].every((step) =>
                            this.matches(row + rowStep * step, column + columnStep * step, player),
                        )
                    ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private matches(row: number, column: number, player: Cell): boolean {
        return (
            row >= 0 &&
            row < ROWS &&
            column >= 0 &&
            column < COLUMNS &&
            this.cells[row][column] === player
        );
    }
}
