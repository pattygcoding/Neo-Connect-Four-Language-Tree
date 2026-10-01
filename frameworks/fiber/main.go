package main

import (
    "strconv"

    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/session"
    "github.com/gofiber/template/html/v2"

    "connectfour/board"
)

var store = session.New()

func main() {
    engine := html.New("./templates", ".html")
    app := fiber.New(fiber.Config{Views: engine})

    app.Get("/", boardPage)
    app.Post("/move", move)
    app.Post("/reset", reset)

    app.Listen(":3000")
}

func boardPage(c *fiber.Ctx) error {
    columns := make([]int, board.Columns)
    for index := range columns {
        columns[index] = index + 1
    }
    return c.Render("board", fiber.Map{
        "board":   currentBoard(c),
        "columns": columns,
    })
}

func move(c *fiber.Ctx) error {
    game := currentBoard(c)
    column, err := strconv.Atoi(c.FormValue("column"))

    if err == nil && column >= 1 && column <= board.Columns && !game.IsOver() && !game.IsFull(column-1) {
        game.Drop(column - 1)
    }

    saveBoard(c, game)
    return c.Redirect("/", fiber.StatusSeeOther)
}

func reset(c *fiber.Ctx) error {
    sess, err := store.Get(c)
    if err != nil {
        return err
    }
    sess.Delete("board")
    if err := sess.Save(); err != nil {
        return err
    }
    return c.Redirect("/", fiber.StatusSeeOther)
}

func currentBoard(c *fiber.Ctx) *board.ConnectFourBoard {
    sess, err := store.Get(c)
    if err != nil {
        return board.New()
    }
    raw, _ := sess.Get("board").(string)
    return board.FromJSON(raw)
}

func saveBoard(c *fiber.Ctx, game *board.ConnectFourBoard) {
    sess, err := store.Get(c)
    if err != nil {
        return
    }
    sess.Set("board", game.ToJSON())
    _ = sess.Save()
}
