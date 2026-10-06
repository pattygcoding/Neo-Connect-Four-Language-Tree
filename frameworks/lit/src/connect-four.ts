import { LitElement, css, html } from "lit";
import { customElement, state } from "lit/decorators.js";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    tone,
    winner,
    type Board,
    type Cell,
} from "./board";

@customElement("connect-four")
export class ConnectFour extends LitElement {
    static styles = css`
        :host {
            display: block;
            max-width: 32rem;
            margin: 0 auto;
            padding: 3rem 1rem;
            text-align: center;
            font-family: system-ui, sans-serif;
            color: #f4f6f5;
        }

        .board {
            margin: 0 auto 1rem;
            background: #1d4ed8;
            border-radius: 0.75rem;
            padding: 0.5rem;
            border-spacing: 0.25rem;
        }

        .cell {
            width: 2.5rem;
            height: 2.5rem;
            border-radius: 50%;
            background: #263238;
            font-weight: 600;
        }

        .cell--x {
            background: #e53935;
        }

        .cell--o {
            background: #fdd835;
            color: #263238;
        }

        .columns {
            display: flex;
            gap: 0.25rem;
            justify-content: center;
        }

        .columns button {
            width: 2.5rem;
            padding: 0.25rem 0;
            border: 0;
            border-radius: 0.375rem;
            background: #334155;
            color: inherit;
            cursor: pointer;
        }

        .columns button:disabled {
            opacity: 0.3;
            cursor: default;
        }
    `;

    @state()
    private board: Board = createBoard();

    @state()
    private moves = 0;

    private get champion(): Cell | null {
        return winner(this.board);
    }

    private get over(): boolean {
        return Boolean(this.champion) || this.moves === ROWS * COLUMNS;
    }

    private get status(): string {
        if (this.champion) {
            return `Player ${this.champion} wins!`;
        }
        if (this.over) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer(this.moves)}, choose a column.`;
    }

    render() {
        return html`
            <h1>Connect Four</h1>
            <p role="status">${this.status}</p>

            <table class="board">
                <tbody>
                    ${[...this.board].reverse().map(
                        (cells) => html`
                            <tr>
                                ${cells.map(
                                    (cell) => html`
                                        <td class="cell cell--${tone(cell)}">${cell}</td>
                                    `,
                                )}
                            </tr>
                        `,
                    )}
                </tbody>
            </table>

            <div class="columns">
                ${Array.from({ length: COLUMNS }, (_, column) => column).map(
                    (column) => html`
                        <button
                            type="button"
                            ?disabled=${this.over || isColumnFull(this.board, column)}
                            @click=${() => this.play(column)}
                        >
                            ${column + 1}
                        </button>
                    `,
                )}
            </div>

            <button type="button" @click=${this.reset}>New game</button>
        `;
    }

    private play(column: number): void {
        if (this.over || isColumnFull(this.board, column)) {
            return;
        }
        this.board = drop(this.board, column, currentPlayer(this.moves));
        this.moves += 1;
    }

    private reset(): void {
        this.board = createBoard();
        this.moves = 0;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "connect-four": ConnectFour;
    }
}
