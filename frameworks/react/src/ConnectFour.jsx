import { useState } from "react";

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
        <section className="game">
            <h1>Connect Four</h1>

            <p role="status">
                {champion
                    ? `Player ${champion} wins!`
                    : over
                    ? "It's a tie!"
                    : `Player ${currentPlayer(moves)}, choose a column.`}
            </p>

            <table className="board">
                <tbody>
                    {[...board].reverse().map((cells, rowIndex) => (
                        <tr key={rowIndex}>
                            {cells.map((cell, columnIndex) => (
                                <td key={columnIndex} className={`cell cell--${cell.toLowerCase()}`}>
                                    {cell}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>

            <div className="columns">
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

            <button type="button" className="reset" onClick={reset}>
                New game
            </button>
        </section>
    );
}
