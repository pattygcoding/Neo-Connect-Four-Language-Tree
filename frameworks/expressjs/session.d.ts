import type { Game } from "./board";

declare module "express-session" {
    interface SessionData {
        board?: Game;
    }
}
