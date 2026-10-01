package main

import (
    "net/http"
    "strconv"

    "github.com/gin-contrib/sessions"
    "github.com/gin-contrib/sessions/cookie"
    "github.com/gin-gonic/gin"

    "connectfour/board"
)

func main() {
    router := gin.Default()
    router.LoadHTMLGlob("templates/*.html")

    store := cookie.NewStore([]byte("change-me-in-production"))
    router.Use(sessions.Sessions("connectfour", store))

    router.GET("/", boardPage)
    router.POST("/move", move)
    router.POST("/reset", reset)

    router.Run(":8080")
}

func boardPage(c *gin.Context) {
    columns := make([]int, board.Columns)
    for index := range columns {
        columns[index] = index + 1
    }
    c.HTML(http.StatusOK, "board.html", gin.H{
        "board":   currentBoard(c),
        "columns": columns,
    })
}

func move(c *gin.Context) {
    game := currentBoard(c)
    column, err := strconv.Atoi(c.PostForm("column"))

    if err == nil && column >= 1 && column <= board.Columns && !game.IsOver() {
        if !game.IsFull(column - 1) {
            game.Drop(column - 1)
        }
    }

    saveBoard(c, game)
    c.Redirect(http.StatusSeeOther, "/")
}

func reset(c *gin.Context) {
    session := sessions.Default(c)
    session.Delete("board")
    session.Save()
    c.Redirect(http.StatusSeeOther, "/")
}

func currentBoard(c *gin.Context) *board.ConnectFourBoard {
    raw, _ := sessions.Default(c).Get("board").(string)
    return board.FromJSON(raw)
}

func saveBoard(c *gin.Context, game *board.ConnectFourBoard) {
    session := sessions.Default(c)
    session.Set("board", game.ToJSON())
    session.Save()
}
