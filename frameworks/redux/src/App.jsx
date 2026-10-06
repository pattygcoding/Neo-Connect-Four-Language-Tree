import { useDispatch, useSelector } from "react-redux";

import {
    play,
    reset,
    selectBoard,
    selectMoves,
    selectOver,
    selectStatus,
} from "./features/game/gameSlice";
import { COLUMNS, isColumnFull } from "./board";

export default function App() {
    const dispatch = useDispatch();
    const board = useSelector(selectBoard);
    const moves = useSelector(selectMoves);
    const over = useSelector(selectOver);
    const status = useSelector(selectStatus);

    return (
        <main className="game">
            <h1>Connect Four</h1>
            <p role="status">{status}</p>

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
                {Array.from({ length: COLUMNS }, (_, column) => (
                    <button
                        key={column}
                        type="button"
                        disabled={over || isColumnFull(board, column)}
                        onClick={() => dispatch(play(column))}
                    >
                        {column + 1}
                    </button>
                ))}
            </div>

            <button type="button" onClick={() => dispatch(reset())}>
                New game
            </button>
            <p className="moves">{moves} moves played</p>
        </main>
    );
}
