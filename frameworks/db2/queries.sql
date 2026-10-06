-- Render the board: a VALUES-derived grid left-joined onto the cells view and
-- collapsed with LISTAGG, Db2's ordered string aggregate.
SELECT
    g.row_index,
    LISTAGG(COALESCE(c.player, '.'), ' ') WITHIN GROUP (ORDER BY g.column_index) AS board_row
FROM (
    SELECT r.row_index, c.column_index
    FROM (VALUES 6, 5, 4, 3, 2, 1) AS r(row_index)
    CROSS JOIN (VALUES 1, 2, 3, 4, 5, 6, 7) AS c(column_index)
) AS g
LEFT JOIN cells AS c
       ON c.game_id = 1
      AND c.x = g.column_index
      AND c.y = g.row_index
GROUP BY g.row_index
ORDER BY g.row_index DESC;

-- Bucket the discs by their diagonal offset to look for a run of four.
SELECT
    player,
    (y - x) AS diagonal_up,
    (y + x) AS diagonal_down,
    COUNT(*) AS run_length
FROM cells
WHERE game_id = 1
GROUP BY player, (y - x), (y + x)
HAVING COUNT(*) >= 4
FETCH FIRST 5 ROWS ONLY;
