package com.example.connectfour

import io.ktor.http.ContentType
import io.ktor.server.application.Application
import io.ktor.server.application.call
import io.ktor.server.engine.embeddedServer
import io.ktor.server.html.respondHtml
import io.ktor.server.netty.Netty
import io.ktor.server.request.receiveParameters
import io.ktor.server.response.respondRedirect
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import io.ktor.server.sessions.Sessions
import io.ktor.server.sessions.cookie
import io.ktor.server.sessions.get
import io.ktor.server.sessions.set
import kotlinx.html.ButtonType
import kotlinx.html.FormMethod
import kotlinx.html.body
import kotlinx.html.button
import kotlinx.html.div
import kotlinx.html.form
import kotlinx.html.h1
import kotlinx.html.head
import kotlinx.html.p
import kotlinx.html.table
import kotlinx.html.tbody
import kotlinx.html.td
import kotlinx.html.title
import kotlinx.html.tr

data class GameSession(val board: String)

fun main() {
    embeddedServer(Netty, port = 8080, host = "0.0.0.0", module = Application::module)
        .start(wait = true)
}

fun Application.module() {
    install(Sessions) {
        cookie<GameSession>("connectfour") {
            cookie.path = "/"
            cookie.httpOnly = true
        }
    }

    routing {
        get("/") {
            val board = boardOf(call)
            call.respondHtml {
                head { title("Connect Four") }
                body {
                    h1 { +"Connect Four" }
                    p { +statusLine(board) }
                    table {
                        tbody {
                            board.rowsTopDown().forEach { row ->
                                tr {
                                    row.forEach { cell ->
                                        td(classes = "cell cell--${cell.lowercase()}") { +cell }
                                    }
                                }
                            }
                        }
                    }
                    form(action = "/move", method = FormMethod.post) {
                        (1..COLUMNS).forEach { column ->
                            button(type = ButtonType.submit) {
                                name = "column"
                                value = column.toString()
                                disabled = board.isOver
                                +"$column"
                            }
                        }
                    }
                    form(action = "/reset", method = FormMethod.post) {
                        button(type = ButtonType.submit) { +"New game" }
                    }
                }
            }
        }

        post("/move") {
            val board = boardOf(call)
            val column = call.receiveParameters()["column"]?.toIntOrNull()
            if (column != null && column in 1..COLUMNS && !board.isOver && !board.isFull(column - 1)) {
                board.drop(column - 1)
            }
            call.sessions.set(GameSession(board.encode()))
            call.respondRedirect("/")
        }

        post("/reset") {
            call.sessions.set(GameSession(ConnectFourBoard().encode()))
            call.respondRedirect("/")
        }
    }
}

private fun boardOf(call: io.ktor.server.application.ApplicationCall): ConnectFourBoard =
    ConnectFourBoard.decode(call.sessions.get<GameSession>()?.board)

private fun statusLine(board: ConnectFourBoard): String {
    board.winner?.let { return "Player $it wins!" }
    if (board.isOver) {
        return "It's a tie!"
    }
    return "Player ${board.currentPlayer}, choose a column."
}
