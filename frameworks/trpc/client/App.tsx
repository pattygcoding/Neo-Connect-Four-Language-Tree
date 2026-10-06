import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createTRPCProxyClient, httpBatchLink } from "@trpc/client";

import type { AppRouter } from "../server/router";

const trpc = createTRPCProxyClient<AppRouter>({
    links: [httpBatchLink({ url: "http://localhost:3000" })],
});

export default function App() {
    const queryClient = useQueryClient();
    const board = useQuery({ queryKey: ["board"], queryFn: () => trpc.board.query() });

    const move = useMutation({
        mutationFn: (column: number) => trpc.move.mutate({ column }),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ["board"] }),
    });

    const reset = useMutation({
        mutationFn: () => trpc.reset.mutate(),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ["board"] }),
    });

    if (!board.data) {
        return <p>Loading...</p>;
    }

    return (
        <main className="game">
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
        </main>
    );
}
