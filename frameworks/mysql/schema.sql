CREATE DATABASE IF NOT EXISTS connect_four
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE connect_four;

DROP VIEW IF EXISTS board_cells;
DROP TABLE IF EXISTS moves;
DROP TABLE IF EXISTS games;

CREATE TABLE games (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished   BOOLEAN NOT NULL DEFAULT FALSE,
    winner     CHAR(1) NULL,
    PRIMARY KEY (id),
    CONSTRAINT chk_winner CHECK (winner IN ('X', 'O'))
) ENGINE = InnoDB;

CREATE TABLE moves (
    id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id   INT UNSIGNED NOT NULL,
    turn      TINYINT UNSIGNED NOT NULL,
    player    CHAR(1) NOT NULL,
    column_no TINYINT UNSIGNED NOT NULL,
    row_no    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uniq_turn (game_id, turn),
    UNIQUE KEY uniq_cell (game_id, column_no, row_no),
    CONSTRAINT fk_moves_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE,
    CONSTRAINT chk_player CHECK (player IN ('X', 'O')),
    CONSTRAINT chk_column CHECK (column_no BETWEEN 1 AND 7),
    CONSTRAINT chk_row CHECK (row_no BETWEEN 1 AND 6)
) ENGINE = InnoDB;

CREATE VIEW board_cells AS
SELECT
    g.id AS game_id,
    rows_all.row_no,
    cols_all.column_no,
    COALESCE(m.player, '.') AS cell
FROM games AS g
CROSS JOIN (
    SELECT 1 AS row_no UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) AS rows_all
CROSS JOIN (
    SELECT 1 AS column_no UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7
) AS cols_all
LEFT JOIN moves AS m
    ON m.game_id = g.id
   AND m.row_no = rows_all.row_no
   AND m.column_no = cols_all.column_no;
