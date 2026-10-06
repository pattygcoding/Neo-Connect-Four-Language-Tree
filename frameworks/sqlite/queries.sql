-- Render the 6x7 board: a recursive CTE numbers the rows, VALUES lists the
-- columns, and the cells view is left-joined onto every intersection.
WITH RECURSIVE grid(row_index) AS (
    SELECT 6
    UNION ALL
    SELECT row_index - 1 FROM grid WHERE row_index > 1
),
columns(column_index) AS (
    VALUES (1), (2), (3), (4), (5), (6), (7)
)
SELECT
    row_index,
    group_concat(COALESCE(c.player, '.'), ' ') AS board_row
FROM grid
CROSS JOIN columns
LEFT JOIN cells AS c
       ON c.game_id = 1
      AND c.x = column_index
      AND c.y = row_index
GROUP BY row_index
ORDER BY row_index DESC;

-- Collapse each column into a JSON array of discs, bottom-first.
SELECT
    column_number,
    json_group_array(player) AS discs
FROM moves
WHERE game_id = 1
GROUP BY column_number
ORDER BY column_number;

-- Guard the next move with a CHECK-like read: is the column still open?
SELECT column_number, COUNT(*) AS height
FROM moves
WHERE game_id = 1
GROUP BY column_number
HAVING COUNT(*) >= 6;
