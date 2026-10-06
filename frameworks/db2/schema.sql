CREATE TABLE games (
    game_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    player     VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (game_id)
);

CREATE TABLE moves (
    move_id       INTEGER GENERATED ALWAYS AS IDENTITY,
    game_id       INTEGER NOT NULL,
    turn_no       INTEGER NOT NULL,
    player        CHAR(1) NOT NULL,
    column_number SMALLINT NOT NULL,
    PRIMARY KEY (move_id),
    CONSTRAINT uq_moves_turn UNIQUE (game_id, turn_no),
    CONSTRAINT fk_moves_games FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE,
    CONSTRAINT ck_moves_player CHECK (player IN ('X', 'O')),
    CONSTRAINT ck_moves_column CHECK (column_number BETWEEN 1 AND 7)
);

CREATE INDEX ix_moves_game_column ON moves (game_id, column_number, turn_no);

CREATE VIEW cells AS
    SELECT
        game_id,
        column_number AS x,
        player,
        ROW_NUMBER() OVER (PARTITION BY game_id, column_number ORDER BY turn_no) AS y
    FROM moves;
