CREATE SEQUENCE IF NOT EXISTS game_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS games (
    game_id    BIGINT NOT NULL DEFAULT NEXTVAL(game_seq),
    player     VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (game_id)
);

CREATE TABLE IF NOT EXISTS moves (
    move_id       BIGINT NOT NULL AUTO_INCREMENT,
    game_id       BIGINT NOT NULL,
    turn_no       INT NOT NULL,
    player        CHAR(1) NOT NULL,
    column_number TINYINT NOT NULL,
    PRIMARY KEY (move_id),
    CONSTRAINT fk_moves_games FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE,
    CONSTRAINT uq_moves_turn UNIQUE (game_id, turn_no),
    CONSTRAINT ck_moves_player CHECK (player IN ('X', 'O')),
    CONSTRAINT ck_moves_column CHECK (column_number BETWEEN 1 AND 7)
);

CREATE INDEX IF NOT EXISTS ix_moves_game_column ON moves (game_id, column_number, turn_no);

CREATE OR REPLACE VIEW cells AS
    SELECT
        game_id,
        column_number AS x,
        player,
        ROW_NUMBER() OVER (PARTITION BY game_id, column_number ORDER BY turn_no) AS y
    FROM moves;
