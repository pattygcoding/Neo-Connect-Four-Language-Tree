-- Start a game; CREATE ONLY returns the single record we just made.
LET $game = (CREATE ONLY game CONTENT { player: 'demo' }).id;

-- Drop discs. SurrealDB stores the game as a typed record link.
CREATE move CONTENT { game: $game, turn_no: 1, player: 'X', column_number: 1 };
CREATE move CONTENT { game: $game, turn_no: 2, player: 'O', column_number: 1 };
CREATE move CONTENT { game: $game, turn_no: 3, player: 'X', column_number: 2 };
CREATE move CONTENT { game: $game, turn_no: 4, player: 'O', column_number: 2 };
CREATE move CONTENT { game: $game, turn_no: 5, player: 'X', column_number: 3 };
CREATE move CONTENT { game: $game, turn_no: 6, player: 'O', column_number: 3 };
CREATE move CONTENT { game: $game, turn_no: 7, player: 'X', column_number: 4 };

-- The move log, newest last, following the record link back to the game.
SELECT turn_no, player, column_number, played_at
FROM move
WHERE game = $game
ORDER BY turn_no;

-- Stack each column and count its discs with SurrealQL's group aggregation.
SELECT column_number, count() AS height
FROM move
WHERE game = $game
GROUP BY column_number
ORDER BY column_number;

-- Close the game once someone has won.
UPDATE $game SET status = 'finished';

-- Live queries stream new moves to a subscriber as they are written.
LIVE SELECT * FROM move WHERE game = $game;
