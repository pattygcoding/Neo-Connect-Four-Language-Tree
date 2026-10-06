INSERT INTO games (game_id, player) VALUES ('8d1f2c00-0000-0000-0000-000000000001', 'demo');

INSERT INTO moves (game_id, turn_no, player, column_number) VALUES
    ('8d1f2c00-0000-0000-0000-000000000001', 1, 'X', 1),
    ('8d1f2c00-0000-0000-0000-000000000001', 2, 'O', 1),
    ('8d1f2c00-0000-0000-0000-000000000001', 3, 'X', 2),
    ('8d1f2c00-0000-0000-0000-000000000001', 4, 'O', 2),
    ('8d1f2c00-0000-0000-0000-000000000001', 5, 'X', 3),
    ('8d1f2c00-0000-0000-0000-000000000001', 6, 'O', 3),
    ('8d1f2c00-0000-0000-0000-000000000001', 7, 'X', 4);

-- Top disc and height per column, found with argMax (the value at the max turn).
SELECT
    column_number,
    argMax(player, turn_no) AS top_disc,
    max(turn_no) AS last_turn,
    count() AS height
FROM moves
WHERE game_id = '8d1f2c00-0000-0000-0000-000000000001'
GROUP BY column_number
ORDER BY column_number;

-- Every column's discs in play order.
SELECT
    column_number,
    groupArray(player) AS discs
FROM moves
WHERE game_id = '8d1f2c00-0000-0000-0000-000000000001'
GROUP BY column_number
ORDER BY column_number;

-- Attach each game to its most recent move with an ANY LEFT JOIN.
SELECT g.player, m.player AS last_mover, m.turn_no
FROM games AS g
ANY LEFT JOIN (
    SELECT game_id, argMax(player, turn_no) AS player, max(turn_no) AS turn_no
    FROM moves
    GROUP BY game_id
) AS m USING (game_id);

-- The materialized view keeps per-column totals without scanning raw moves.
SELECT game_id, column_number, sum(discs) AS height
FROM column_heights
GROUP BY game_id, column_number
ORDER BY column_number;
