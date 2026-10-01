USE connect_four;

DELETE FROM games;

INSERT INTO games (id, finished, winner) VALUES (1, TRUE, 'X');

INSERT INTO moves (game_id, turn, player, column_no, row_no) VALUES
    (1, 1, 'X', 1, 1),
    (1, 2, 'O', 1, 2),
    (1, 3, 'X', 2, 1),
    (1, 4, 'O', 2, 2),
    (1, 5, 'X', 3, 1),
    (1, 6, 'O', 3, 2),
    (1, 7, 'X', 4, 1);
