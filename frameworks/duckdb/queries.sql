-- Build the grid from DuckDB's range() tables and list aggregation.
SELECT
    r AS row_index,
    list(COALESCE(c.player, '.') ORDER BY col) AS board_row
FROM range(6, 0, -1) AS rows(r)
CROSS JOIN range(1, 8) AS columns(col)
LEFT JOIN cells AS c
       ON c.game_id = 1
      AND c.x = col
      AND c.y = r
GROUP BY r
ORDER BY r DESC;

-- Pivot the discs by player: how many did each stack into every column?
PIVOT (
    SELECT column_number, player
    FROM moves
    WHERE game_id = 1
)
ON player
USING count(*);

-- The winning line, found by comparing diagonal offsets.
SELECT DISTINCT player
FROM (
    SELECT
        player,
        count(*) OVER (PARTITION BY player, y) AS row_run,
        count(*) OVER (PARTITION BY player, x) AS column_run,
        count(*) OVER (PARTITION BY player, y - x) AS up_run,
        count(*) OVER (PARTITION BY player, y + x) AS down_run
    FROM cells
    WHERE game_id = 1
)
WHERE row_run >= 4 OR column_run >= 4 OR up_run >= 4 OR down_run >= 4;
