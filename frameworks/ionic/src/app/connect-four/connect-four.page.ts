import { Component } from "@angular/core";

import { COLUMNS, ConnectFourBoard } from "./board";

@Component({
    selector: "app-connect-four",
    templateUrl: "./connect-four.page.html",
})
export class ConnectFourPage {
    readonly columns = Array.from({ length: COLUMNS }, (_, index) => index);
    board = new ConnectFourBoard();

    get champion(): string | null {
        return this.board.winner;
    }

    get status(): string {
        if (this.champion) {
            return `Player ${this.champion} wins!`;
        }
        if (this.board.isOver) {
            return "It's a tie!";
        }
        return `Player ${this.board.currentPlayer}, choose a column.`;
    }

    play(column: number): void {
        this.board.play(column);
    }

    isFull(column: number): boolean {
        return this.board.isFull(column);
    }

    reset(): void {
        this.board = new ConnectFourBoard();
    }
}
