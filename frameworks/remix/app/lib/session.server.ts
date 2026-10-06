import { createCookieSessionStorage } from "react-router";

import { createBoard, type Board } from "./board";

const storage = createCookieSessionStorage({
    cookie: {
        name: "connectfour",
        httpOnly: true,
        path: "/",
        sameSite: "lax",
        secrets: ["change-me-in-production"],
    },
});

export interface GameState {
    cells: Board;
}

export async function loadBoard(request: Request): Promise<GameState> {
    const session = await storage.getSession(request.headers.get("Cookie"));
    const stored = session.get("board") as Board | undefined;
    return { cells: stored ?? createBoard() };
}

export async function commitBoard(request: Request, cells: Board) {
    const session = await storage.getSession(request.headers.get("Cookie"));
    session.set("board", cells);
    return Response.json(
        { cells },
        { headers: { "Set-Cookie": await storage.commitSession(session) } },
    );
}
