import type { HttpContext } from "@adonisjs/core/http";

import { COLUMNS, ConnectFourBoard } from "#services/board";

export default class GamesController {
    async show({ session, view }: HttpContext) {
        const board = ConnectFourBoard.decode(session.get("board"));
        return view.render("game/board", { board });
    }

    async move({ request, response, session }: HttpContext) {
        const board = ConnectFourBoard.decode(session.get("board"));
        const column = Number(request.input("column"));

        if (
            !board.isOver &&
            column >= 1 &&
            column <= COLUMNS &&
            !board.isFull(column - 1)
        ) {
            board.drop(column - 1);
        }

        session.put("board", board.encode());
        return response.redirect("/");
    }

    async reset({ response, session }: HttpContext) {
        session.forget("board");
        return response.redirect("/");
    }
}
