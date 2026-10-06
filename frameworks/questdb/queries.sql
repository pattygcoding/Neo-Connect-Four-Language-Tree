INSERT INTO games (game_id, player, started_at)
VALUES (1, 'demo', now());

INSERT INTO moves (game_id, turn_no, player, column_number, played_at)
SELECT 1, turn_no, player, column_number, dateadd('s', turn_no, now())
FROM (
    VALUES
        (1, 'X', 1),
        (2, 'O', 1),
        (3, 'X', 2),
        (4, 'O', 2),
        (5, 'X', 3),
        (6, 'O', 3),
        (7, 'X', 4)
);

-- Latest disc in each column (QuestDB's LATEST ON ... PARTITION BY).
SELECT game_id, column_number, player, turn_no, played_at
FROM moves
LATEST ON played_at PARTITION BY game_id, column_number;

-- Moves per second, bucketed by QuestDB's time-series SAMPLE BY.
SELECT played_at, count() AS moves
FROM moves
WHERE game_id = 1
SAMPLE BY 1s;

-- Which player is ahead, joining the latest move with the game row.
SELECT g.player, g.started_at, m.player AS last_mover, m.turn_no
FROM games AS g
ASOF JOIN moves AS m
    ON g.game_id = m.game_id;
