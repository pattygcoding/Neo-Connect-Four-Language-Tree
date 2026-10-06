import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QApplication,
    QGridLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

from board import COLUMNS, ROWS, ConnectFourBoard

DISC_COLORS = {
    "X": "#e53935",
    "O": "#fdd835",
    ".": "#263238",
}


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Connect Four")
        self.board = ConnectFourBoard()

        self.status = QLabel()
        self.status.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.grid = QGridLayout()
        self.grid.setSpacing(4)
        self.buttons = QGridLayout()
        self.buttons.setSpacing(4)

        layout = QVBoxLayout()
        layout.addWidget(self.status)
        layout.addLayout(self.grid)
        layout.addLayout(self.buttons)

        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        self.render()

    def render(self):
        champion = self.board.winner
        self.status.setText(
            f"Player {champion} wins!"
            if champion
            else "It's a tie!"
            if self.board.is_over
            else f"Player {self.board.current_player}, choose a column."
        )

        while self.grid.count():
            self.grid.takeAt(0).widget().deleteLater()
        while self.buttons.count():
            self.buttons.takeAt(0).widget().deleteLater()

        for display_row, row in enumerate(range(ROWS - 1, -1, -1)):
            for column in range(COLUMNS):
                cell = self.board.cell(row, column)
                disc = QLabel(cell)
                disc.setFixedSize(48, 48)
                disc.setAlignment(Qt.AlignmentFlag.AlignCenter)
                disc.setStyleSheet(
                    f"background-color: {DISC_COLORS[cell]}; border-radius: 24px; color: white;"
                )
                self.grid.addWidget(disc, display_row, column)

        for column in range(COLUMNS):
            button = QPushButton(str(column + 1))
            button.setEnabled(not self.board.is_over and not self.board.is_full(column))
            button.clicked.connect(lambda _=False, target=column: self.play(target))
            self.buttons.addWidget(button, 0, column)

    def play(self, column):
        if not self.board.is_over and not self.board.is_full(column):
            self.board.drop(column)
            self.render()


def main():
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
