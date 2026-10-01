const connectFour = db.getSiblingDB("connect_four");

connectFour.games.drop();

connectFour.createCollection("games", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["startedAt", "finished", "moves"],
            additionalProperties: false,
            properties: {
                _id: { bsonType: "int" },
                startedAt: { bsonType: "date", description: "when the game began" },
                finished: { bsonType: "bool" },
                winner: { bsonType: ["string", "null"], enum: ["X", "O", null] },
                moves: {
                    bsonType: "array",
                    description: "every disc, in the order it was dropped",
                    maxItems: 42,
                    items: {
                        bsonType: "object",
                        required: ["turn", "player", "column", "row"],
                        additionalProperties: false,
                        properties: {
                            turn: { bsonType: "int", minimum: 1, maximum: 42 },
                            player: { bsonType: "string", enum: ["X", "O"] },
                            column: { bsonType: "int", minimum: 1, maximum: 7 },
                            row: { bsonType: "int", minimum: 1, maximum: 6 }
                        }
                    }
                }
            }
        }
    }
});

connectFour.games.createIndex({ "moves.column": 1, "moves.row": 1 });
connectFour.games.createIndex({ winner: 1 });
