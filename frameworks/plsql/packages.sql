CREATE OR REPLACE PACKAGE connect_four_pkg AS
    FUNCTION player_at (p_game_id IN NUMBER, p_row IN NUMBER, p_column IN NUMBER) RETURN CHAR;
    FUNCTION winner (p_game_id IN NUMBER) RETURN CHAR;
    FUNCTION board (p_game_id IN NUMBER) RETURN VARCHAR2;
    PROCEDURE drop_disc (p_game_id IN NUMBER, p_column IN NUMBER);
END connect_four_pkg;
/

CREATE OR REPLACE PACKAGE BODY connect_four_pkg AS

    FUNCTION player_at (p_game_id IN NUMBER, p_row IN NUMBER, p_column IN NUMBER) RETURN CHAR IS
        l_player CHAR(1);
    BEGIN
        SELECT player
          INTO l_player
          FROM moves
         WHERE game_id = p_game_id
           AND column_number = p_column
           AND turn_no = (
               SELECT MIN(turn_no)
                 FROM moves
                WHERE game_id = p_game_id
                  AND column_number = p_column
           ) + p_row - 1;
        RETURN l_player;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '.';
    END player_at;

    FUNCTION has_line (
        p_game_id IN NUMBER,
        p_player  IN CHAR,
        p_row_step IN NUMBER,
        p_column_step IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        FOR r IN 1 .. 6 LOOP
            FOR c IN 1 .. 7 LOOP
                IF player_at(p_game_id, r, c) = p_player
                   AND player_at(p_game_id, r + p_row_step, c + p_column_step) = p_player
                   AND player_at(p_game_id, r + 2 * p_row_step, c + 2 * p_column_step) = p_player
                   AND player_at(p_game_id, r + 3 * p_row_step, c + 3 * p_column_step) = p_player THEN
                    RETURN TRUE;
                END IF;
            END LOOP;
        END LOOP;
        RETURN FALSE;
    END has_line;

    FUNCTION winner (p_game_id IN NUMBER) RETURN CHAR IS
    BEGIN
        FOR p IN (SELECT 'X' AS player FROM dual UNION ALL SELECT 'O' FROM dual) LOOP
            IF has_line(p_game_id, p.player, 0, 1)
               OR has_line(p_game_id, p.player, 1, 0)
               OR has_line(p_game_id, p.player, 1, 1)
               OR has_line(p_game_id, p.player, 1, -1) THEN
                RETURN p.player;
            END IF;
        END LOOP;
        RETURN NULL;
    END winner;

    FUNCTION board (p_game_id IN NUMBER) RETURN VARCHAR2 IS
        l_board VARCHAR2(4000);
    BEGIN
        FOR r IN REVERSE 1 .. 6 LOOP
            FOR c IN 1 .. 7 LOOP
                l_board := l_board || player_at(p_game_id, r, c) || ' ';
            END LOOP;
            l_board := l_board || CHR(10);
        END LOOP;
        RETURN RTRIM(l_board);
    END board;

    PROCEDURE drop_disc (p_game_id IN NUMBER, p_column IN NUMBER) IS
        l_height    NUMBER;
        l_next_turn NUMBER;
        l_player    CHAR(1);
    BEGIN
        IF p_column < 1 OR p_column > 7 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Column is out of range.');
        END IF;

        SELECT COUNT(*)
          INTO l_height
          FROM moves
         WHERE game_id = p_game_id
           AND column_number = p_column;

        IF l_height >= 6 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Column is full.');
        END IF;

        SELECT NVL(MAX(turn_no), 0) + 1
          INTO l_next_turn
          FROM moves
         WHERE game_id = p_game_id;

        l_player := CASE WHEN MOD(l_next_turn, 2) = 1 THEN 'X' ELSE 'O' END;

        INSERT INTO moves (game_id, turn_no, player, column_number)
        VALUES (p_game_id, l_next_turn, l_player, p_column);
    END drop_disc;

END connect_four_pkg;
/
