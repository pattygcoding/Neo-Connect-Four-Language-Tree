SET TERM ^ ;

CREATE OR ALTER EXCEPTION e_column_range 'Column is out of range.';
CREATE OR ALTER EXCEPTION e_column_full  'Column is full.';

CREATE OR ALTER PROCEDURE drop_disc (p_game_id INTEGER, p_column SMALLINT)
AS
    DECLARE VARIABLE l_height    INTEGER;
    DECLARE VARIABLE l_next_turn INTEGER;
    DECLARE VARIABLE l_player    CHAR(1);
BEGIN
    IF (p_column < 1 OR p_column > 7) THEN
        EXCEPTION e_column_range;

    SELECT COUNT(*) FROM moves
     WHERE game_id = :p_game_id AND column_number = :p_column
      INTO l_height;

    IF (l_height >= 6) THEN
        EXCEPTION e_column_full;

    SELECT COALESCE(MAX(turn_no), 0) + 1 FROM moves
     WHERE game_id = :p_game_id
      INTO l_next_turn;

    IF (MOD(:l_next_turn, 2) = 1) THEN
        l_player = 'X';
    ELSE
        l_player = 'O';

    INSERT INTO moves (game_id, turn_no, player, column_number)
    VALUES (:p_game_id, :l_next_turn, :l_player, :p_column);
END^

CREATE OR ALTER PROCEDURE board (p_game_id INTEGER)
RETURNS (row_index INTEGER, board_row VARCHAR(40))
AS
    DECLARE VARIABLE l_row INTEGER;
BEGIN
    l_row = 6;
    WHILE (l_row >= 1) DO
    BEGIN
        SELECT LIST(COALESCE(c.player, '.'), ' ')
          FROM (
              SELECT 1 AS column_index FROM rdb$database UNION ALL
              SELECT 2 FROM rdb$database UNION ALL
              SELECT 3 FROM rdb$database UNION ALL
              SELECT 4 FROM rdb$database UNION ALL
              SELECT 5 FROM rdb$database UNION ALL
              SELECT 6 FROM rdb$database UNION ALL
              SELECT 7 FROM rdb$database
          ) AS g
          LEFT JOIN cells AS c
            ON c.game_id = :p_game_id
           AND c.x = g.column_index
           AND c.y = :l_row
          INTO board_row;

        row_index = l_row;
        SUSPEND;
        l_row = l_row - 1;
    END
END^

SET TERM ; ^
