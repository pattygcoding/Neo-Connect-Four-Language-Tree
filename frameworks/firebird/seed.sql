INSERT INTO games (player) VALUES ('demo');

EXECUTE BLOCK AS
BEGIN
    EXECUTE PROCEDURE drop_disc(1, 1);
    EXECUTE PROCEDURE drop_disc(1, 1);
    EXECUTE PROCEDURE drop_disc(1, 2);
    EXECUTE PROCEDURE drop_disc(1, 2);
    EXECUTE PROCEDURE drop_disc(1, 3);
    EXECUTE PROCEDURE drop_disc(1, 3);
    EXECUTE PROCEDURE drop_disc(1, 4);
END;

SELECT row_index, board_row FROM board(1);

SELECT * FROM cells WHERE game_id = 1 ORDER BY y, x;
