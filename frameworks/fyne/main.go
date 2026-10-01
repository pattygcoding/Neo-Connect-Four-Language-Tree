package main

import (
    "fmt"

    "fyne.io/fyne/v2"
    "fyne.io/fyne/v2/app"
    "fyne.io/fyne/v2/container"
    "fyne.io/fyne/v2/widget"

    "connectfour/board"
)

type gameUI struct {
    game   *board.ConnectFourBoard
    cells  [board.Rows][board.Columns]*widget.Label
    status *widget.Label
}

func main() {
    ui := &gameUI{game: board.New()}

    application := app.New()
    window := application.NewWindow("Connect Four")

    window.SetContent(ui.build())
    window.Resize(fyne.NewSize(560, 560))
    ui.refresh()

    window.ShowAndRun()
}

func (ui *gameUI) build() fyne.CanvasObject {
    ui.status = widget.NewLabel("")
    ui.status.Alignment = fyne.TextAlignCenter
    ui.status.TextStyle = fyne.TextStyle{Bold: true}

    grid := container.NewGridWithColumns(board.Columns, ui.cellObjects()...)
    buttons := container.NewGridWithColumns(board.Columns, ui.buttonObjects()...)

    return container.NewBorder(
        ui.status,
        widget.NewButton("New game", ui.reset),
        nil,
        nil,
        container.NewVBox(grid, buttons),
    )
}

func (ui *gameUI) cellObjects() []fyne.CanvasObject {
    objects := make([]fyne.CanvasObject, 0, board.Rows*board.Columns)
    for row := 0; row < board.Rows; row++ {
        for column := 0; column < board.Columns; column++ {
            label := widget.NewLabel(board.Empty)
            label.Alignment = fyne.TextAlignCenter
            label.TextStyle = fyne.TextStyle{Monospace: true}
            ui.cells[row][column] = label
            objects = append(objects, label)
        }
    }
    return objects
}

func (ui *gameUI) buttonObjects() []fyne.CanvasObject {
    objects := make([]fyne.CanvasObject, 0, board.Columns)
    for column := 0; column < board.Columns; column++ {
        index := column
        objects = append(objects, widget.NewButton(fmt.Sprintf("%d", index+1), func() {
            ui.play(index)
        }))
    }
    return objects
}

func (ui *gameUI) play(column int) {
    if !ui.game.IsOver() {
        ui.game.Drop(column)
    }
    ui.refresh()
}

func (ui *gameUI) reset() {
    ui.game = board.New()
    ui.refresh()
}

func (ui *gameUI) refresh() {
    rows := ui.game.RowsTopDown()
    for row := 0; row < board.Rows; row++ {
        for column := 0; column < board.Columns; column++ {
            ui.cells[row][column].SetText(rows[row][column])
        }
    }
    ui.status.SetText(ui.statusText())
}

func (ui *gameUI) statusText() string {
    switch {
    case ui.game.Winner() != "":
        return fmt.Sprintf("Player %s wins!", ui.game.Winner())
    case ui.game.IsOver():
        return "It's a tie!"
    default:
        return fmt.Sprintf("Player %s, choose a column", ui.game.CurrentPlayer())
    }
}
