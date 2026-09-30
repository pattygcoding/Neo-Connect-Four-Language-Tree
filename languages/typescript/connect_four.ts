declare const process: any;
declare function require(name: string): any;
const readline = require("readline");

const ROWS: number = 6;
const COLS: number = 7;
const EMPTY: string = ".";
const PLAYERS: string[] = ["X", "O"];
const BORDER: string = "+" + "-".repeat(COLS * 2 - 1) + "+";
const LABELS: string =
    " " + Array.from({ length: COLS }, (_v, i: number) => i + 1).join(" ");
const HEADER: string =
    "=== Connect Four ===\n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

function newBoard(): string[][] {
    return Array.from({ length: ROWS }, () => new Array<string>(COLS).fill(EMPTY));
}

function render(board: string[][]): string {
    const lines: string[] = [LABELS, BORDER];
    for (let row = ROWS - 1; row >= 0; row--) {
        lines.push("|" + board[row].join(" ") + "|");
    }
    lines.push(BORDER);
    return lines.join("\n");
}

function lowestEmptyRow(board: string[][], column: number): number {
    for (let row = 0; row < ROWS; row++) {
        if (board[row][column] === EMPTY) {
            return row;
        }
    }
    return -1;
}

function hasFour(board: string[][], player: string): boolean {
    const at = (r: number, c: number): boolean => board[r][c] === player;
    for (let r = 0; r < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r, c + 1) && at(r, c + 2) && at(r, c + 3)) return true;
        }
    }
    for (let r = 0; r + 3 < ROWS; r++) {
        for (let c = 0; c < COLS; c++) {
            if (at(r, c) && at(r + 1, c) && at(r + 2, c) && at(r + 3, c)) return true;
        }
    }
    for (let r = 0; r + 3 < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r + 1, c + 1) && at(r + 2, c + 2) && at(r + 3, c + 3)) {
                return true;
            }
        }
    }
    for (let r = 3; r < ROWS; r++) {
        for (let c = 0; c + 3 < COLS; c++) {
            if (at(r, c) && at(r - 1, c + 1) && at(r - 2, c + 2) && at(r - 3, c + 3)) {
                return true;
            }
        }
    }
    return false;
}

function isWholeNumber(token: string): boolean {
    return /^[+-]?[0-9]+$/.test(token);
}

const rl = readline.createInterface({ input: process.stdin, terminal: false });
const pendingLines: string[] = [];
let pendingResolver: ((line: string | null) => void) | null = null;
let inputClosed: boolean = false;

rl.on("line", (line: string) => {
    if (pendingResolver) {
        const resolve = pendingResolver;
        pendingResolver = null;
        resolve(line);
    } else {
        pendingLines.push(line);
    }
});
rl.on("close", () => {
    inputClosed = true;
    if (pendingResolver) {
        const resolve = pendingResolver;
        pendingResolver = null;
        resolve(null);
    }
});

function readLine(): Promise<string | null> {
    return new Promise((resolve) => {
        if (pendingLines.length) {
            resolve(pendingLines.shift() as string);
        } else if (inputClosed) {
            resolve(null);
        } else {
            pendingResolver = resolve;
        }
    });
}

async function askColumn(board: string[][], player: string): Promise<number | null> {
    for (;;) {
        process.stdout.write("Player " + player + ", choose a column (1-7): ");
        const raw: string | null = await readLine();
        if (raw === null) {
            process.stdout.write("\nInput closed. Goodbye.\n");
            return null;
        }
        const token: string = raw.trim();
        let message: string;
        if (token === "") {
            message = "Invalid input: no column entered.";
        } else if (!isWholeNumber(token)) {
            message = 'Invalid input: "' + token + '" is not a whole number.';
        } else {
            const value: number = Number(token);
            if (!(value >= 1 && value <= COLS)) {
                message = 'Invalid input: "' + token + '" is out of range (1-7).';
            } else if (lowestEmptyRow(board, value - 1) === -1) {
                message = "Column " + value + " is full.";
            } else {
                return value - 1;
            }
        }
        process.stdout.write("\n" + message + "\n");
    }
}

async function main(): Promise<void> {
    const board: string[][] = newBoard();
    process.stdout.write(HEADER + "\n" + render(board) + "\n");
    let moves: number = 0;
    let playerIndex: number = 0;
    for (;;) {
        const player: string = PLAYERS[playerIndex];
        const column: number | null = await askColumn(board, player);
        if (column === null) {
            return;
        }
        board[lowestEmptyRow(board, column)][column] = player;
        moves++;
        process.stdout.write("\n" + render(board) + "\n");
        if (hasFour(board, player)) {
            process.stdout.write("Player " + player + " wins!\n");
            return;
        }
        if (moves === ROWS * COLS) {
            process.stdout.write("It's a tie!\n");
            return;
        }
        playerIndex = 1 - playerIndex;
    }
}

main().then(() => {
    rl.close();
    process.stdout.write("", () => process.exit(0));
});
