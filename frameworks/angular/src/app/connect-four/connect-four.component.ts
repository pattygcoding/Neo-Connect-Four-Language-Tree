import { Component } from "@angular/core";
import { CommonModule } from "@angular/common";

import {
    Board,
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "./board";

@Component({
    selector: "app-connect-four",
    standalone: true,
    imports: [CommonModule],
    templateUrl: "./connect-four.component.html",
    styleUrls: ["./connect-four.component.css"],
})
export class ConnectFourComponent {
    readonly columns = Array.from({ length: COLUMNS }, (_, index) => index);
    board: Board = createBoard();
    moves = 0;

    get champion(): string | null {
        return winner(this.board);
    }

    get over(): boolean {
        return this.champion !== null || this.moves === ROWS * COLUMNS;
    }

    get status(): string {
        if (this.champion) {
            return `Player ${this.champion} wins!`;
        }
        if (this.over) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer(this.moves)}, choose a column.`;
    }

    rows(): Board {
        return [...this.board].reverse();
    }

    isFull(column: number): boolean {
        return isColumnFull(this.board, column);
    }

    play(column: number): void {
        if (this.over || isColumnFull(this.board, column)) {
            return;
        }
        this.board = drop(this.board, column, currentPlayer(this.moves));
        this.moves += 1;
    }

    reset(): void {
        this.board = createBoard();
        this.moves = 0;
    }
}
