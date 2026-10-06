-- Render the board with a recursive CTE (MariaDB 10.2+).
WITH RECURSIVE grid(row_index) AS (
    SELECT 6
    UNION ALL
    SELECT row_index - 1 FROM grid WHERE row_index > 1
),
columns(column_index) AS (
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
)
SELECT
    row_index,
    GROUP_CONCAT(COALESCE(c.player, '.') ORDER BY column_index SEPARATOR ' ') AS board_row
FROM grid
CROSS JOIN columns
LEFT JOIN cells AS c
       ON c.game_id = 1
      AND c.x = column_index
      AND c.y = row_index
GROUP BY row_index
ORDER BY row_index DESC;

-- The winning line, computed with a window function over the move history.
SELECT DISTINCT player
FROM (
    SELECT
        player,
        column_number,
        y,
        y - column_number AS diagonal_up,
        y + column_number AS diagonal_down,
        COUNT(*) OVER (PARTITION BY player, y) AS row_run,
        COUNT(*) OVER (PARTITION BY player, column_number) AS column_run,
        COUNT(*) OVER (PARTITION BY player, y - column_number) AS up_run,
        COUNT(*) OVER (PARTITION BY player, y + column_number) AS down_run
    FROM cells
    WHERE game_id = 1
) runs
WHERE row_run >= 4 OR column_run >= 4 OR up_run >= 4 OR down_run >= 4;
