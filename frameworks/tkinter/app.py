import tkinter as tk

from board import COLUMNS, ROWS, Board

CELL = 64
GAP = 6
DISC_COLOURS = {"X": "#ef4444", "O": "#facc15"}
FRAME_COLOUR = "#1d4ed8"
SLOT_COLOUR = "#0b1220"


class ConnectFourApp:
    """A Tkinter window with a Canvas board; click a column to drop a disc."""

    def __init__(self, root):
        self.root = root
        self.board = Board()

        root.title("Connect Four - Tkinter")

        self.status = tk.Label(root, text="", font=("Segoe UI", 14, "bold"))
        self.status.pack(pady=(12, 4))

        self.canvas = tk.Canvas(
            root,
            width=COLUMNS * CELL,
            height=ROWS * CELL,
            bg=FRAME_COLOUR,
            highlightthickness=0,
        )
        self.canvas.pack(padx=12, pady=4)
        self.canvas.bind("<Button-1>", self.on_click)

        tk.Button(root, text="New game", command=self.reset).pack(pady=(4, 12))

        self.refresh()

    def cell_box(self, row, column):
        """Canvas coordinates of a slot; row 0 (the bottom row) is drawn last."""
        top = (ROWS - 1 - row) * CELL
        left = column * CELL
        return left + GAP, top + GAP, left + CELL - GAP, top + CELL - GAP

    def refresh(self):
        self.canvas.delete("all")
        for row in range(ROWS):
            for column in range(COLUMNS):
                colour = DISC_COLOURS.get(self.board.cells[row][column], SLOT_COLOUR)
                self.canvas.create_oval(*self.cell_box(row, column), fill=colour, outline="")
        self.status.config(text=self.status_text())

    def status_text(self):
        winner = self.board.winner()
        if winner:
            return "Player %s wins!" % winner
        if self.board.moves == ROWS * COLUMNS:
            return "It's a tie!"
        return "Player %s, choose a column" % self.board.current_player

    def on_click(self, event):
        column = event.x // CELL
        if 0 <= column < COLUMNS and not self.board.is_over() and not self.board.is_full(column):
            self.board.drop(column)
            self.refresh()

    def reset(self):
        self.board = Board()
        self.refresh()


def main():
    root = tk.Tk()
    ConnectFourApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
