INSERT INTO games (player) VALUES ('demo');

INSERT ALL
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 1, 'X', 1)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 2, 'O', 1)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 3, 'X', 2)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 4, 'O', 2)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 5, 'X', 3)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 6, 'O', 3)
    INTO moves (game_id, turn_no, player, column_number) VALUES (1, 7, 'X', 4)
SELECT 1 FROM dual;

COMMIT;

SELECT * FROM cells WHERE game_id = 1;
