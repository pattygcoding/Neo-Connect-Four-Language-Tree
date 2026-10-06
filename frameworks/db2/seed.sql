INSERT INTO games (player) VALUES ('demo');

INSERT INTO moves (game_id, turn_no, player, column_number) VALUES
    (1, 1, 'X', 1),
    (1, 2, 'O', 1),
    (1, 3, 'X', 2),
    (1, 4, 'O', 2),
    (1, 5, 'X', 3),
    (1, 6, 'O', 3),
    (1, 7, 'X', 4);

SELECT * FROM cells WHERE game_id = 1 ORDER BY y, x;
