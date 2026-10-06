CREATE SEQUENCE move_seq START 1;

CREATE TABLE games (
    game_id    INTEGER PRIMARY KEY,
    player     TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE moves (
    move_id       BIGINT DEFAULT nextval('move_seq'),
    game_id       INTEGER NOT NULL REFERENCES games (game_id),
    turn_no       INTEGER NOT NULL,
    player        TEXT NOT NULL CHECK (player IN ('X', 'O')),
    column_number INTEGER NOT NULL CHECK (column_number BETWEEN 1 AND 7),
    UNIQUE (game_id, turn_no)
);

CREATE VIEW cells AS
    SELECT
        game_id,
        column_number AS x,
        player,
        row_number() OVER (PARTITION BY game_id, column_number ORDER BY turn_no) AS y
    FROM moves;
