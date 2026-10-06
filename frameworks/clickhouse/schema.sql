CREATE TABLE IF NOT EXISTS games (
    game_id    UUID,
    player     LowCardinality(String),
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree
ORDER BY (game_id);

CREATE TABLE IF NOT EXISTS moves (
    game_id       UUID,
    turn_no       UInt8,
    player        LowCardinality(String),
    column_number UInt8,
    played_at     DateTime DEFAULT now()
) ENGINE = MergeTree
ORDER BY (game_id, turn_no);

CREATE MATERIALIZED VIEW IF NOT EXISTS column_heights
ENGINE = SummingMergeTree
ORDER BY (game_id, column_number) AS
    SELECT
        game_id,
        column_number,
        toUInt32(count()) AS discs
    FROM moves
    GROUP BY game_id, column_number;
