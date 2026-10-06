import { initTRPC } from "@trpc/server";
import { z } from "zod";

import { COLUMNS, ConnectFourBoard } from "./board";

const t = initTRPC.create();

export interface Context {
    board: ConnectFourBoard;
}

export const appRouter = t.router({
    board: t.procedure.query(({ ctx }) => ctx.board.view()),

    move: t.procedure
        .input(z.object({ column: z.number().int().min(0).max(COLUMNS - 1) }))
        .mutation(({ ctx, input }) => {
            ctx.board.play(input.column);
            return ctx.board.view();
        }),

    reset: t.procedure.mutation(({ ctx }) => {
        ctx.board.reset();
        return ctx.board.view();
    }),
});

export type AppRouter = typeof appRouter;
