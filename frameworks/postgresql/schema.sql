CREATE TABLE games (
    id         BIGSERIAL PRIMARY KEY,
    player     TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE moves (
    id            BIGSERIAL PRIMARY KEY,
    game_id       BIGINT  NOT NULL REFERENCES games (id) ON DELETE CASCADE,
    turn          INTEGER NOT NULL CHECK (turn > 0),
    player        TEXT    NOT NULL CHECK (player IN ('X', 'O')),
    column_number INTEGER NOT NULL CHECK (column_number BETWEEN 1 AND 7),
    UNIQUE (game_id, turn)
);

CREATE INDEX moves_game_turn_idx ON moves (game_id, turn);

CREATE VIEW cells AS
SELECT
    game_id,
    column_number AS x,
    row_number AS y,
    player
FROM (
    SELECT
        game_id,
        column_number,
        player,
        ROW_NUMBER() OVER (PARTITION BY game_id, column_number ORDER BY turn) AS row_number
    FROM moves
) stacked;

CREATE FUNCTION board(p_game_id BIGINT)
RETURNS TABLE (row_index INTEGER, cells TEXT[])
LANGUAGE sql
STABLE
AS $$
    SELECT
        row_index,
        ARRAY(
            SELECT COALESCE(
                (
                    SELECT c.player
                    FROM cells c
                    WHERE c.game_id = p_game_id
                      AND c.x = column_index
                      AND c.y = row_index
                ),
                '.'
            )
            FROM generate_series(1, 7) AS column_index
        )
    FROM generate_series(6, 1, -1) AS row_index
$$;

CREATE FUNCTION winner(p_game_id BIGINT)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT player FROM (
        SELECT g.player
        FROM cells g
        JOIN cells s1 ON s1.game_id = g.game_id AND s1.x = g.x + 1 AND s1.y = g.y AND s1.player = g.player
        JOIN cells s2 ON s2.game_id = g.game_id AND s2.x = g.x + 2 AND s2.y = g.y AND s2.player = g.player
        JOIN cells s3 ON s3.game_id = g.game_id AND s3.x = g.x + 3 AND s3.y = g.y AND s3.player = g.player
        WHERE g.game_id = p_game_id
        UNION ALL
        SELECT g.player
        FROM cells g
        JOIN cells s1 ON s1.game_id = g.game_id AND s1.x = g.x AND s1.y = g.y + 1 AND s1.player = g.player
        JOIN cells s2 ON s2.game_id = g.game_id AND s2.x = g.x AND s2.y = g.y + 2 AND s2.player = g.player
        JOIN cells s3 ON s3.game_id = g.game_id AND s3.x = g.x AND s3.y = g.y + 3 AND s3.player = g.player
        WHERE g.game_id = p_game_id
        UNION ALL
        SELECT g.player
        FROM cells g
        JOIN cells s1 ON s1.game_id = g.game_id AND s1.x = g.x + 1 AND s1.y = g.y + 1 AND s1.player = g.player
        JOIN cells s2 ON s2.game_id = g.game_id AND s2.x = g.x + 2 AND s2.y = g.y + 2 AND s2.player = g.player
        JOIN cells s3 ON s3.game_id = g.game_id AND s3.x = g.x + 3 AND s3.y = g.y + 3 AND s3.player = g.player
        WHERE g.game_id = p_game_id
        UNION ALL
        SELECT g.player
        FROM cells g
        JOIN cells s1 ON s1.game_id = g.game_id AND s1.x = g.x + 1 AND s1.y = g.y - 1 AND s1.player = g.player
        JOIN cells s2 ON s2.game_id = g.game_id AND s2.x = g.x + 2 AND s2.y = g.y - 2 AND s2.player = g.player
        JOIN cells s3 ON s3.game_id = g.game_id AND s3.x = g.x + 3 AND s3.y = g.y - 3 AND s3.player = g.player
        WHERE g.game_id = p_game_id
    ) lines
    LIMIT 1
$$;

CREATE FUNCTION drop_disc(p_game_id BIGINT, p_column INTEGER)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    next_turn   INTEGER;
    next_player TEXT;
    height      INTEGER;
BEGIN
    SELECT COALESCE(MAX(turn), 0) + 1 INTO next_turn
    FROM moves WHERE game_id = p_game_id;

    SELECT COUNT(*) INTO height
    FROM moves WHERE game_id = p_game_id AND column_number = p_column;

    IF p_column < 1 OR p_column > 7 THEN
        RAISE EXCEPTION 'column % is out of range', p_column;
    END IF;
    IF height >= 6 THEN
        RAISE EXCEPTION 'column % is full', p_column;
    END IF;

    next_player := CASE WHEN next_turn % 2 = 1 THEN 'X' ELSE 'O' END;

    INSERT INTO moves (game_id, turn, player, column_number)
    VALUES (p_game_id, next_turn, next_player, p_column);
END;
$$;
