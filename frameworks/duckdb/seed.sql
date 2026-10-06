INSERT INTO games (game_id, player) VALUES (1, 'demo');

INSERT INTO moves (game_id, turn_no, player, column_number)
SELECT 1, turn_no, player, column_number
FROM (
    VALUES
        (1, 'X', 1),
        (2, 'O', 1),
        (3, 'X', 2),
        (4, 'O', 2),
        (5, 'X', 3),
        (6, 'O', 3),
        (7, 'X', 4)
) AS seed(turn_no, player, column_number);

SELECT * FROM cells WHERE game_id = 1 ORDER BY y, x;
