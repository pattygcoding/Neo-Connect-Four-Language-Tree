USE connect_four;

-- Render the stored board, bottom row last.
SELECT
    b.row_no,
    CONCAT('|', GROUP_CONCAT(b.cell ORDER BY b.column_no SEPARATOR ' '), '|') AS board_row
FROM board_cells AS b
WHERE b.game_id = 1
GROUP BY b.row_no
ORDER BY b.row_no DESC;

-- Find four-in-a-row by treating each move as belonging to four "rays"
-- (horizontal, vertical and both diagonals) and grouping consecutive cells.
WITH rays AS (
    SELECT game_id, player, row_no, column_no, 'horizontal' AS direction, row_no AS line_key, column_no AS position FROM moves
    UNION ALL
    SELECT game_id, player, row_no, column_no, 'vertical', column_no, row_no FROM moves
    UNION ALL
    SELECT game_id, player, row_no, column_no, 'diag_up', row_no + column_no, row_no FROM moves
    UNION ALL
    SELECT game_id, player, row_no, column_no, 'diag_down', row_no - column_no, row_no FROM moves
),
grouped AS (
    SELECT
        game_id,
        player,
        direction,
        line_key,
        position,
        position - ROW_NUMBER() OVER (
            PARTITION BY game_id, player, direction, line_key
            ORDER BY position
        ) AS run_id
    FROM rays
)
SELECT
    game_id,
    player,
    direction,
    MIN(position) AS run_from,
    MAX(position) AS run_to,
    COUNT(*) AS run_length
FROM grouped
GROUP BY game_id, player, direction, line_key, run_id
HAVING COUNT(*) >= 4
ORDER BY run_length DESC, game_id, player;

-- Leaderboard: games won per player.
SELECT
    winner AS player,
    COUNT(*) AS games_won
FROM games
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY games_won DESC, player;

-- How the discs are distributed across the columns of one game.
SELECT
    column_no,
    COUNT(*) AS discs
FROM moves
WHERE game_id = 1
GROUP BY column_no
ORDER BY column_no;
