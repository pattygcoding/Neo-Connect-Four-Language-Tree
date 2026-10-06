import { useState } from "preact/hooks";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

export default function ConnectFour() {
    const [board, setBoard] = useState(createBoard);
    const [moves, setMoves] = useState(0);

    const champion = winner(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    function play(column) {
        if (over || isColumnFull(board, column)) {
            return;
        }
        setBoard(drop(board, column, currentPlayer(moves)));
        setMoves(moves + 1);
    }

    function reset() {
        setBoard(createBoard());
        setMoves(0);
    }

    return (
        <section class="game">
            <h1>Connect Four</h1>

            <p role="status">
                {champion
                    ? `Player ${champion} wins!`
                    : over
                    ? "It's a tie!"
                    : `Player ${currentPlayer(moves)}, choose a column.`}
            </p>

            <table class="board">
                <tbody>
                    {[...board].reverse().map((cells, rowIndex) => (
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
                        onClick={() => play(index)}
                        disabled={over || isColumnFull(board, index)}
                    >
                        {index + 1}
                    </button>
                ))}
            </div>

            <button type="button" onClick={reset}>
                New game
            </button>
        </section>
    );
}
