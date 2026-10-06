import { PrismaClient } from "@prisma/client";

import { COLUMNS, ConnectFourBoard } from "./board";

const prisma = new PrismaClient();

export async function newGame(player: string) {
    return prisma.game.create({
        data: { player },
    });
}

export async function boardFor(gameId: number): Promise<ConnectFourBoard> {
    const game = await prisma.game.findUniqueOrThrow({
        where: { id: gameId },
        include: { moves: { orderBy: { id: "asc" } } },
    });

    const board = new ConnectFourBoard();
    for (const move of game.moves) {
        board.play(move.column);
    }
    return board;
}

export async function play(gameId: number, column: number): Promise<ConnectFourBoard> {
    const board = await boardFor(gameId);
    if (column < 0 || column >= COLUMNS) {
        return board;
    }

    const player = board.currentPlayer;
    if (!board.play(column)) {
        return board;
    }

    await prisma.move.create({
        data: { gameId, column, player },
    });
    return board;
}

export async function history(gameId: number) {
    return prisma.move.findMany({
        where: { gameId },
        orderBy: { id: "asc" },
        select: { player: true, column: true },
    });
}
