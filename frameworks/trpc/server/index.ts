import { createHTTPServer } from "@trpc/server/adapters/standalone";

import { ConnectFourBoard } from "./board";
import { appRouter, type Context } from "./router";

const boards = new Map<string, ConnectFourBoard>();

createHTTPServer({
    router: appRouter,
    createContext({ req }): Context {
        const id = req.headers.cookie?.match(/sid=([^;]+)/)?.[1] ?? "default";
        if (!boards.has(id)) {
            boards.set(id, new ConnectFourBoard());
        }
        return { board: boards.get(id)! };
    },
}).listen(3000);

console.log("tRPC server on http://localhost:3000");
