package main

import (
    "html/template"
    "io"
    "net/http"
    "strconv"

    "github.com/gorilla/sessions"
    "github.com/labstack/echo-contrib/session"
    "github.com/labstack/echo/v4"

    "connectfour/board"
)

type templateRenderer struct {
    templates *template.Template
}

func (renderer *templateRenderer) Render(writer io.Writer, name string, data interface{}, _ echo.Context) error {
    return renderer.templates.ExecuteTemplate(writer, name, data)
}

func main() {
    server := echo.New()
    server.Renderer = &templateRenderer{
        templates: template.Must(template.ParseGlob("templates/*.html")),
    }
    server.Use(session.Middleware(sessions.NewCookieStore([]byte("change-me-in-production"))))

    server.GET("/", boardPage)
    server.POST("/move", move)
    server.POST("/reset", reset)

    server.Logger.Fatal(server.Start(":8080"))
}

func boardPage(c echo.Context) error {
    columns := make([]int, board.Columns)
    for index := range columns {
        columns[index] = index + 1
    }
    return c.Render(http.StatusOK, "board.html", map[string]interface{}{
        "board":   currentBoard(c),
        "columns": columns,
    })
}

func move(c echo.Context) error {
    game := currentBoard(c)
    column, err := strconv.Atoi(c.FormValue("column"))

    if err == nil && column >= 1 && column <= board.Columns && !game.IsOver() {
        if !game.IsFull(column - 1) {
            game.Drop(column - 1)
        }
    }

    saveBoard(c, game)
    return c.Redirect(http.StatusSeeOther, "/")
}

func reset(c echo.Context) error {
    store, _ := session.Get("connectfour", c)
    delete(store.Values, "board")
    store.Save(c.Request(), c.Response())
    return c.Redirect(http.StatusSeeOther, "/")
}

func currentBoard(c echo.Context) *board.ConnectFourBoard {
    store, _ := session.Get("connectfour", c)
    raw, _ := store.Values["board"].(string)
    return board.FromJSON(raw)
}

func saveBoard(c echo.Context, game *board.ConnectFourBoard) {
    store, _ := session.Get("connectfour", c)
    store.Values["board"] = game.ToJSON()
    store.Save(c.Request(), c.Response())
}
