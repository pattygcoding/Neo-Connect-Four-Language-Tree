CREATE TABLE IF NOT EXISTS moves (
    game_id       LONG,
    turn_no       INT,
    player        SYMBOL CAPACITY 2 CACHE,
    column_number INT,
    played_at     TIMESTAMP
) TIMESTAMP(played_at) PARTITION BY DAY WAL;

CREATE TABLE IF NOT EXISTS games (
    game_id    LONG,
    player     SYMBOL CAPACITY 64 CACHE,
    started_at TIMESTAMP
) TIMESTAMP(started_at) PARTITION BY MONTH WAL;
