const connectFour = db.getSiblingDB("connect_four");

connectFour.games.replaceOne(
    { _id: 1 },
    {
        _id: 1,
        startedAt: new Date("2024-01-01T00:00:00Z"),
        finished: true,
        winner: "X",
        moves: [
            { turn: 1, player: "X", column: 1, row: 1 },
            { turn: 2, player: "O", column: 1, row: 2 },
            { turn: 3, player: "X", column: 2, row: 1 },
            { turn: 4, player: "O", column: 2, row: 2 },
            { turn: 5, player: "X", column: 3, row: 1 },
            { turn: 6, player: "O", column: 3, row: 2 },
            { turn: 7, player: "X", column: 4, row: 1 }
        ]
    },
    { upsert: true }
);
