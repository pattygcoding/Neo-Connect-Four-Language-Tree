package board

import "encoding/json"

const (
    Rows    = 6
    Columns = 7
    Empty   = "."
)

var (
    players    = [2]string{"X", "O"}
    directions = [4][2]int{{0, 1}, {1, 0}, {1, 1}, {1, -1}}
)

type ConnectFourBoard struct {
    Cells [Rows][Columns]string `json:"cells"`
    Moves int                   `json:"moves"`
}

func New() *ConnectFourBoard {
    game := &ConnectFourBoard{}
    for row := range game.Cells {
        for column := range game.Cells[row] {
            game.Cells[row][column] = Empty
        }
    }
    return game
}

func FromJSON(raw string) *ConnectFourBoard {
    if raw == "" {
        return New()
    }
    game := New()
    if err := json.Unmarshal([]byte(raw), game); err != nil {
        return New()
    }
    return game
}

func (game *ConnectFourBoard) ToJSON() string {
    data, err := json.Marshal(game)
    if err != nil {
        return ""
    }
    return string(data)
}

func (game *ConnectFourBoard) CurrentPlayer() string {
    return players[game.Moves%len(players)]
}

func (game *ConnectFourBoard) Winner() string {
    for _, player := range players {
        if game.hasLine(player) {
            return player
        }
    }
    return ""
}

func (game *ConnectFourBoard) IsOver() bool {
    return game.Winner() != "" || game.Moves == Rows*Columns
}

func (game *ConnectFourBoard) IsFull(column int) bool {
    return game.lowestEmptyRow(column) < 0
}

func (game *ConnectFourBoard) Drop(column int) bool {
    row := game.lowestEmptyRow(column)
    if row < 0 {
        return false
    }
    game.Cells[row][column] = game.CurrentPlayer()
    game.Moves++
    return true
}

func (game *ConnectFourBoard) RowsTopDown() [Rows][Columns]string {
    var rows [Rows][Columns]string
    for index := 0; index < Rows; index++ {
        rows[index] = game.Cells[Rows-1-index]
    }
    return rows
}

func (game *ConnectFourBoard) lowestEmptyRow(column int) int {
    for row := 0; row < Rows; row++ {
        if game.Cells[row][column] == Empty {
            return row
        }
    }
    return -1
}

func (game *ConnectFourBoard) hasLine(player string) bool {
    for row := 0; row < Rows; row++ {
        for column := 0; column < Columns; column++ {
            if !game.matches(row, column, player) {
                continue
            }
            for _, direction := range directions {
                if game.matches(row+direction[0], column+direction[1], player) &&
                    game.matches(row+direction[0]*2, column+direction[1]*2, player) &&
                    game.matches(row+direction[0]*3, column+direction[1]*3, player) {
                    return true
                }
            }
        }
    }
    return false
}

func (game *ConnectFourBoard) matches(row, column int, player string) bool {
    return row >= 0 && row < Rows && column >= 0 && column < Columns && game.Cells[row][column] == player
}
