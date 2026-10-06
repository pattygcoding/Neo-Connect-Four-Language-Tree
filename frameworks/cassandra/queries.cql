USE connect_four;

-- Start a game; two players share one partition keyed by game_id.
INSERT INTO games (game_id, player, next_turn, status, created_at)
VALUES (550e8400-e29b-41d4-a716-446655440000, 'demo', 1, 'in_progress', toTimestamp(now()));

-- Reserve the next turn with a lightweight transaction so two players can
-- never claim the same move. The `[applied]` column tells the caller who won.
UPDATE games
SET next_turn = 2, status = 'in_progress'
WHERE game_id = 550e8400-e29b-41d4-a716-446655440000
IF next_turn = 1;

-- Append a disc to the top of a column; the list length is the row it lands in.
UPDATE board_by_game
SET discs = discs + ['X']
WHERE game_id = 550e8400-e29b-41d4-a716-446655440000 AND column_number = 1;

-- Log the move; timeuuid clustering keeps it in play order without a counter.
INSERT INTO moves_by_game (game_id, move_id, turn, player, column_number)
VALUES (550e8400-e29b-41d4-a716-446655440000, now(), 1, 'X', 1);

-- Read the whole board for one game (all seven columns, ordered).
SELECT column_number, discs
FROM board_by_game
WHERE game_id = 550e8400-e29b-41d4-a716-446655440000;

-- Slice the move log by clustering column instead of scanning the partition.
SELECT turn, player, column_number
FROM moves_by_game
WHERE game_id = 550e8400-e29b-41d4-a716-446655440000;

-- The materialized view answers "what is in progress?" without a scan.
SELECT game_id, player, next_turn
FROM games_by_status
WHERE status = 'in_progress';
