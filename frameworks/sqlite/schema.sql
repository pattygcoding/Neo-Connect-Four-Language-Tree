PRAGMA foreign_keys = ON;

CREATE TABLE games (
    game_id    INTEGER PRIMARY KEY,
    player     TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

CREATE TABLE moves (
    move_id       INTEGER PRIMARY KEY,
    game_id       INTEGER NOT NULL REFERENCES games (game_id) ON DELETE CASCADE,
    turn_no       INTEGER NOT NULL,
    player        TEXT NOT NULL CHECK (player IN ('X', 'O')),
    column_number INTEGER NOT NULL CHECK (column_number BETWEEN 1 AND 7),
    UNIQUE (game_id, turn_no)
) STRICT;

CREATE INDEX ix_moves_game_column ON moves (game_id, column_number, turn_no);

CREATE VIEW cells AS
    SELECT
        game_id,
        column_number AS x,
        player,
        ROW_NUMBER() OVER (PARTITION BY game_id, column_number ORDER BY turn_no) AS y
    FROM moves;
