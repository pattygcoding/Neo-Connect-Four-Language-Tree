import { Form, useLoaderData } from "react-router";

import {
    COLUMNS,
    ROWS,
    countMoves,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
    type Board,
} from "../lib/board";
import { commitBoard, loadBoard } from "../lib/session.server";

export function loader({ request }: { request: Request }) {
    return loadBoard(request);
}

export async function action({ request }: { request: Request }) {
    const board = await loadBoard(request);
    const formData = await request.formData();

    if (formData.get("intent") === "reset") {
        return commitBoard(request, createBoard());
    }

    const column = Number.parseInt(String(formData.get("column")), 10) - 1;
    const playable =
        !winner(board.cells) &&
        countMoves(board.cells) < ROWS * COLUMNS &&
        column >= 0 &&
        column < COLUMNS &&
        !isColumnFull(board.cells, column);

    return commitBoard(request, playable ? drop(board.cells, column) : board.cells);
}

export default function Home() {
    const board: Board = useLoaderData<typeof loader>().cells;
    const moves = countMoves(board);
    const champion = winner(board);
    const over = Boolean(champion) || moves === ROWS * COLUMNS;

    return (
        <main className="game">
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
                    <Form method="post" key={index}>
                        <input type="hidden" name="column" value={index + 1} />
                        <button type="submit" disabled={over || isColumnFull(board, index)}>
                            {index + 1}
                        </button>
                    </Form>
                ))}
            </div>

            <Form method="post">
                <input type="hidden" name="intent" value="reset" />
                <button type="submit">New game</button>
            </Form>
        </main>
    );
}
