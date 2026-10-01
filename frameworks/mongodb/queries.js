db = db.getSiblingDB("connect_four");

// Rebuild the whole 7x6 board from the embedded moves, top row first.
db.games.aggregate([
    { $match: { _id: 1 } },
    {
        $project: {
            board: {
                $map: {
                    input: { $range: [6, 0, -1] },
                    as: "row",
                    in: {
                        $concat: [
                            "|",
                            {
                                $reduce: {
                                    input: {
                                        $map: {
                                            input: { $range: [1, 8] },
                                            as: "column",
                                            in: {
                                                $let: {
                                                    vars: {
                                                        hit: {
                                                            $first: {
                                                                $filter: {
                                                                    input: "$moves",
                                                                    as: "move",
                                                                    cond: {
                                                                        $and: [
                                                                            { $eq: ["$$move.row", "$$row"] },
                                                                            { $eq: ["$$move.column", "$$column"] }
                                                                        ]
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    },
                                                    in: { $ifNull: ["$$hit.player", "."] }
                                                }
                                            }
                                        }
                                    },
                                    initialValue: "",
                                    in: {
                                        $concat: [
                                            "$$value",
                                            { $cond: [{ $eq: ["$$value", ""] }, "", " "] },
                                            "$$this"
                                        ]
                                    }
                                }
                            },
                            "|"
                        ]
                    }
                }
            }
        }
    }
]);

// Find four-in-a-row: spread every move onto four rays and group consecutive
// cells with $setWindowFields (the NoSQL echo of a gaps-and-islands query).
db.games.aggregate([
    { $match: { _id: 1 } },
    { $unwind: "$moves" },
    {
        $project: {
            player: "$moves.player",
            rays: [
                { direction: "horizontal", lineKey: "$moves.row", position: "$moves.column" },
                { direction: "vertical", lineKey: "$moves.column", position: "$moves.row" },
                { direction: "diagUp", lineKey: { $add: ["$moves.row", "$moves.column"] }, position: "$moves.row" },
                { direction: "diagDown", lineKey: { $subtract: ["$moves.row", "$moves.column"] }, position: "$moves.row" }
            ]
        }
    },
    { $unwind: "$rays" },
    {
        $project: {
            player: 1,
            direction: "$rays.direction",
            lineKey: "$rays.lineKey",
            position: "$rays.position"
        }
    },
    {
        $setWindowFields: {
            partitionBy: { player: "$player", direction: "$direction", lineKey: "$lineKey" },
            sortBy: { position: 1 },
            output: { ordinal: { $documentNumber: {} } }
        }
    },
    { $addFields: { runId: { $subtract: ["$position", "$ordinal"] } } },
    {
        $group: {
            _id: { player: "$player", direction: "$direction", lineKey: "$lineKey", runId: "$runId" },
            from: { $min: "$position" },
            to: { $max: "$position" },
            length: { $sum: 1 }
        }
    },
    { $match: { length: { $gte: 4 } } },
    { $project: { _id: 0, player: "$_id.player", direction: "$_id.direction", from: 1, to: 1, length: 1 } }
]);

// Leaderboard: games won per player.
db.games.aggregate([
    { $match: { winner: { $ne: null } } },
    { $group: { _id: "$winner", gamesWon: { $sum: 1 } } },
    { $sort: { gamesWon: -1, _id: 1 } },
    { $project: { _id: 0, player: "$_id", gamesWon: 1 } }
]);

// How the discs are distributed across the columns of one game.
db.games.aggregate([
    { $match: { _id: 1 } },
    { $unwind: "$moves" },
    { $group: { _id: "$moves.column", discs: { $sum: 1 } } },
    { $sort: { _id: 1 } },
    { $project: { _id: 0, column: "$_id", discs: 1 } }
]);
