import { component$, useSignal } from "@builder.io/qwik";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "../lib/board";

export default component$(() => {
    const board = useSignal(createBoard());
    const moves = useSignal(0);

    const champion = winner(board.value);
    const over = Boolean(champion) || moves.value === ROWS * COLUMNS;

    return (
        <main class="game">
            <h1>Connect Four</h1>

            <p role="status">
                {champion
                    ? `Player ${champion} wins!`
                    : over
                    ? "It's a tie!"
                    : `Player ${currentPlayer(moves.value)}, choose a column.`}
            </p>

            <table class="board">
                <tbody>
                    {[...board.value].reverse().map((cells, rowIndex) => (
                        <tr key={rowIndex}>
                            {cells.map((cell, columnIndex) => (
                                <td key={columnIndex} class={`cell cell--${cell.toLowerCase()}`}>
                                    {cell}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>

            <div class="columns">
                {Array.from({ length: COLUMNS }, (_, index) => (
                    <button
                        key={index}
                        type="button"
                        disabled={over || isColumnFull(board.value, index)}
                        onClick$={() => {
                            if (
                                winner(board.value) ||
                                moves.value === ROWS * COLUMNS ||
                                isColumnFull(board.value, index)
                            ) {
                                return;
                            }
                            board.value = drop(board.value, index, currentPlayer(moves.value));
                            moves.value += 1;
                        }}
                    >
                        {index + 1}
                    </button>
                ))}
            </div>

            <button
                type="button"
                onClick$={() => {
                    board.value = createBoard();
                    moves.value = 0;
                }}
            >
                New game
            </button>
        </main>
    );
});
