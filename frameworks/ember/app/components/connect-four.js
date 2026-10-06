import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

import {
    COLUMNS,
    ROWS,
    createBoard,
    currentPlayer,
    drop,
    isColumnFull,
    winner,
} from "../../utils/board";

export default class ConnectFourComponent extends Component {
    @tracked board = createBoard();
    @tracked moves = 0;

    get champion() {
        return winner(this.board);
    }

    get over() {
        return Boolean(this.champion) || this.moves === ROWS * COLUMNS;
    }

    get status() {
        if (this.champion) {
            return `Player ${this.champion} wins!`;
        }
        if (this.over) {
            return "It's a tie!";
        }
        return `Player ${currentPlayer(this.moves)}, choose a column.`;
    }

    get rows() {
        return [...this.board].reverse().map((cells) =>
            cells.map((cell) => ({
                value: cell,
                tone: cell === "." ? "empty" : cell.toLowerCase(),
            })),
        );
    }

    get columns() {
        return Array.from({ length: COLUMNS }, (_, index) => ({
            index,
            label: index + 1,
            disabled: this.over || isColumnFull(this.board, index),
        }));
    }

    @action
    play(column) {
        if (this.over || isColumnFull(this.board, column)) {
            return;
        }
        this.board = drop(this.board, column, currentPlayer(this.moves));
        this.moves += 1;
    }

    @action
    reset() {
        this.board = createBoard();
        this.moves = 0;
    }
}
