import Vapor

struct MoveForm: Content {
    let column: Int
}

func routes(_ app: Application) throws {
    app.get { req async throws -> Response in
        let board = req.session.data["board"].flatMap(ConnectFourBoard.decode) ?? ConnectFourBoard()
        return html(render(board))
    }

    app.post("move") { req async throws -> Response in
        var board = req.session.data["board"].flatMap(ConnectFourBoard.decode) ?? ConnectFourBoard()
        let form = try req.content.decode(MoveForm.self)

        if !board.isOver,
            form.column >= 1,
            form.column <= ConnectFourBoard.columnCount,
            !board.isFull(column: form.column - 1)
        {
            board.drop(column: form.column - 1)
        }

        req.session.data["board"] = board.encoded
        return req.redirect(to: "/")
    }

    app.post("reset") { req async throws -> Response in
        req.session.data["board"] = nil
        return req.redirect(to: "/")
    }
}

private func html(_ body: String) -> Response {
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: body))
}

private func render(_ board: ConnectFourBoard) -> String {
    let status: String
    if let champion = board.winner {
        status = "Player \(champion) wins!"
    } else if board.isOver {
        status = "It's a tie!"
    } else {
        status = "Player \(board.currentPlayer), choose a column."
    }

    let rows = board.rowsTopDown.map { row in
        let cells = row.map { cell in
            "<td class=\"cell cell--\(cell.lowercased())\">\(cell)</td>"
        }.joined()
        return "<tr>\(cells)</tr>"
    }.joined()

    let buttons = (1...ConnectFourBoard.columnCount).map { column in
        let disabled = board.isOver ? " disabled" : ""
        return "<button type=\"submit\" name=\"column\" value=\"\(column)\"\(disabled)>\(column)</button>"
    }.joined()

    return """
        <!doctype html>
        <html lang="en">
        <head><meta charset="utf-8"><title>Connect Four</title></head>
        <body>
        <h1>Connect Four</h1>
        <p>\(status)</p>
        <table class="board">\(rows)</table>
        <form method="post" action="/move">\(buttons)</form>
        <form method="post" action="/reset"><button type="submit">New game</button></form>
        </body>
        </html>
        """
}
