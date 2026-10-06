USE connect_four;

INSERT INTO games (game_id, player, next_turn, status, created_at)
VALUES (8d1f2c00-0000-0000-0000-000000000001, 'demo', 1, 'in_progress', toTimestamp(now()));

UPDATE board_by_game SET discs = discs + ['X'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 1;
UPDATE board_by_game SET discs = discs + ['O'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 1;
UPDATE board_by_game SET discs = discs + ['X'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 2;
UPDATE board_by_game SET discs = discs + ['O'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 2;
UPDATE board_by_game SET discs = discs + ['X'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 3;
UPDATE board_by_game SET discs = discs + ['O'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 3;
UPDATE board_by_game SET discs = discs + ['X'] WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001 AND column_number = 4;

UPDATE games SET next_turn = 8 WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001;

SELECT column_number, discs FROM board_by_game WHERE game_id = 8d1f2c00-0000-0000-0000-000000000001;
