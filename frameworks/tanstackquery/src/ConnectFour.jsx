import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { fetchGame, resetGame, sendMove } from "./api";

export default function ConnectFour() {
    const queryClient = useQueryClient();
    const board = useQuery({ queryKey: ["game"], queryFn: fetchGame });

    const invalidate = () => queryClient.invalidateQueries({ queryKey: ["game"] });
    const move = useMutation({ mutationFn: sendMove, onSuccess: invalidate });
    const reset = useMutation({ mutationFn: resetGame, onSuccess: invalidate });

    if (!board.data) {
        return <p>Loading...</p>;
    }

    return (
        <section className="game">
            <h1>Connect Four</h1>
            <p role="status">{board.data.status}</p>

            <table className="board">
                <tbody>
                    {board.data.rows.map((row, rowIndex) => (
                        <tr key={rowIndex}>
                            {row.map((cell, columnIndex) => (
                                <td key={columnIndex} className={`cell cell--${cell.toLowerCase()}`}>
                                    {cell}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>

            <div className="columns">
                {board.data.full.map((full, column) => (
                    <button
                        key={column}
                        type="button"
                        disabled={board.data?.over || full}
                        onClick={() => move.mutate(column)}
                    >
                        {column + 1}
                    </button>
                ))}
            </div>

            <button type="button" onClick={() => reset.mutate()}>
                New game
            </button>
        </section>
    );
}
