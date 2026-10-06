const ROWS = 6;
const COLUMNS = 7;
const EMPTY = ".";
const PLAYERS = ["X", "O"];
const DIRECTIONS = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
];

$(function () {
    let board = createBoard();
    let moves = 0;

    function createBoard() {
        return Array.from({ length: ROWS }, () => Array(COLUMNS).fill(EMPTY));
    }

    function currentPlayer() {
        return PLAYERS[moves % PLAYERS.length];
    }

    function lowestEmptyRow(column) {
        for (let row = 0; row < ROWS; row += 1) {
            if (board[row][column] === EMPTY) {
                return row;
            }
        }
        return -1;
    }

    function isColumnFull(column) {
        return lowestEmptyRow(column) === -1;
    }

    function winner() {
        for (const player of PLAYERS) {
            if (hasLine(player)) {
                return player;
            }
        }
        return null;
    }

    function matches(row, column, player) {
        return (
            row >= 0 &&
            row < ROWS &&
            column >= 0 &&
            column < COLUMNS &&
            board[row][column] === player
        );
    }

    function hasLine(player) {
        for (let row = 0; row < ROWS; row += 1) {
            for (let column = 0; column < COLUMNS; column += 1) {
                for (const [rowStep, columnStep] of DIRECTIONS) {
                    if (
                        [1, 2, 3].every((step) =>
                            matches(row + rowStep * step, column + columnStep * step, player),
                        )
                    ) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function statusText() {
        const champion = winner();
        if (champion) {
            return `Player ${champion} wins!`;
        }
        if (moves === ROWS * COLUMNS) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer()}, choose a column.`;
    }

    function render() {
        const champion = winner();
        const over = Boolean(champion) || moves === ROWS * COLUMNS;

        $("#status").text(statusText());

        const $tbody = $("#board").empty();
        for (let row = ROWS - 1; row >= 0; row -= 1) {
            const $tr = $("<tr>");
            for (let column = 0; column < COLUMNS; column += 1) {
                const cell = board[row][column];
                const tone = cell === "." ? "empty" : cell.toLowerCase();
                $("<td>")
                    .addClass("cell")
                    .addClass(`cell--${tone}`)
                    .text(cell)
                    .appendTo($tr);
            }
            $tr.appendTo($tbody);
        }

        const $columns = $("#columns").empty();
        for (let column = 0; column < COLUMNS; column += 1) {
            $("<button>")
                .attr("type", "button")
                .prop("disabled", over || isColumnFull(column))
                .text(column + 1)
                .appendTo($columns);
        }
    }

    function play(column) {
        if (winner() || moves === ROWS * COLUMNS || isColumnFull(column)) {
            return;
        }
        board[lowestEmptyRow(column)][column] = currentPlayer();
        moves += 1;
        render();
    }

    $("#columns").on("click", "button", function () {
        play($(this).index());
    });

    $("#reset").on("click", function () {
        board = createBoard();
        moves = 0;
        render();
    });

    render();
});
