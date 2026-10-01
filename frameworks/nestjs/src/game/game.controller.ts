import { Body, Controller, Get, Post, Session } from "@nestjs/common";

import { GameService, GameState, GameView } from "./game.service";

@Controller("game")
export class GameController {
    constructor(private readonly game: GameService) {}

    @Get()
    show(@Session() session: Record<string, unknown>): GameView {
        return this.game.view(this.game.fromState(session.board as GameState));
    }

    @Post("move")
    move(
        @Session() session: Record<string, unknown>,
        @Body("column") column: number,
    ): GameView {
        const state = this.game.play(this.game.fromState(session.board as GameState), Number(column));
        session.board = state;
        return this.game.view(state);
    }

    @Post("reset")
    reset(@Session() session: Record<string, unknown>): GameView {
        delete session.board;
        return this.game.view(this.game.fromState(undefined));
    }
}
