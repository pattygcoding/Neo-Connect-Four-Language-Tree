import { createSignal, For } from "solid-js";

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
    const [board, setBoard] = createSignal(createBoard());
    const [moves, setMoves] = createSignal(0);

    const champion = () => winner(board());
    const over = () => Boolean(champion()) || moves() === ROWS * COLUMNS;

    function play(column) {
        if (over() || isColumnFull(board(), column)) {
            return;
        }
        setBoard(drop(board(), column, currentPlayer(moves())));
        setMoves(moves() + 1);
    }

    function reset() {
        setBoard(createBoard());
        setMoves(0);
    }

    return (
        <section class="game">
            <h1>Connect Four</h1>

            <p role="status">
                {champion()
                    ? `Player ${champion()} wins!`
                    : over()
                    ? "It's a tie!"
                    : `Player ${currentPlayer(moves())}, choose a column.`}
            </p>

            <table class="board">
                <tbody>
                    <For each={[...board()].reverse()}>
                        {(cells) => (
                            <tr>
                                <For each={cells}>
                                    {(cell) => (
                                        <td class={`cell cell--${cell.toLowerCase()}`}>{cell}</td>
                                    )}
                                </For>
                            </tr>
                        )}
                    </For>
                </tbody>
            </table>

            <div class="columns">
                <For each={Array.from({ length: COLUMNS }, (_, index) => index)}>
                    {(column) => (
                        <button
                            type="button"
                            onClick={() => play(column)}
                            disabled={over() || isColumnFull(board(), column)}
                        >
                            {column + 1}
                        </button>
                    )}
                </For>
            </div>

            <button type="button" onClick={reset}>
                New game
            </button>
        </section>
    );
}
