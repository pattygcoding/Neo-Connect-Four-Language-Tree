CREATE OR ALTER FUNCTION dbo.fn_Winner (@GameId INT)
RETURNS CHAR(1)
AS
BEGIN
    DECLARE @player CHAR(1);

    SELECT TOP (1) @player = c.player
    FROM dbo.Cells AS c
    WHERE c.game_id = @GameId
      AND (
        EXISTS (
            SELECT 1
            FROM dbo.Cells AS s1
            JOIN dbo.Cells AS s2 ON s2.game_id = s1.game_id AND s2.x = s1.x + 1 AND s2.y = s1.y AND s2.player = s1.player
            JOIN dbo.Cells AS s3 ON s3.game_id = s1.game_id AND s3.x = s1.x + 2 AND s3.y = s1.y AND s3.player = s1.player
            WHERE s1.game_id = c.game_id AND s1.x = c.x AND s1.y = c.y AND s1.player = c.player
        )
        OR EXISTS (
            SELECT 1
            FROM dbo.Cells AS s1
            JOIN dbo.Cells AS s2 ON s2.game_id = s1.game_id AND s2.x = s1.x AND s2.y = s1.y + 1 AND s2.player = s1.player
            JOIN dbo.Cells AS s3 ON s3.game_id = s1.game_id AND s3.x = s1.x AND s3.y = s1.y + 2 AND s3.player = s1.player
            WHERE s1.game_id = c.game_id AND s1.x = c.x AND s1.y = c.y AND s1.player = c.player
        )
        OR EXISTS (
            SELECT 1
            FROM dbo.Cells AS s1
            JOIN dbo.Cells AS s2 ON s2.game_id = s1.game_id AND s2.x = s1.x + 1 AND s2.y = s1.y + 1 AND s2.player = s1.player
            JOIN dbo.Cells AS s3 ON s3.game_id = s1.game_id AND s3.x = s1.x + 2 AND s3.y = s1.y + 2 AND s3.player = s1.player
            WHERE s1.game_id = c.game_id AND s1.x = c.x AND s1.y = c.y AND s1.player = c.player
        )
        OR EXISTS (
            SELECT 1
            FROM dbo.Cells AS s1
            JOIN dbo.Cells AS s2 ON s2.game_id = s1.game_id AND s2.x = s1.x + 1 AND s2.y = s1.y - 1 AND s2.player = s1.player
            JOIN dbo.Cells AS s3 ON s3.game_id = s1.game_id AND s3.x = s1.x + 2 AND s3.y = s1.y - 2 AND s3.player = s1.player
            WHERE s1.game_id = c.game_id AND s1.x = c.x AND s1.y = c.y AND s1.player = c.player
        )
      );

    RETURN @player;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_Board (@GameId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        RowIndex = gs.y,
        Cells = STRING_AGG(
            COALESCE(c.player, '.'),
            ' '
        ) WITHIN GROUP (ORDER BY gs.x)
    FROM (VALUES (1), (2), (3), (4), (5), (6)) AS gs(y)
    CROSS JOIN (VALUES (1), (2), (3), (4), (5), (6), (7)) AS gs2(x)
    LEFT JOIN dbo.Cells AS c ON c.game_id = @GameId AND c.x = gs2.x AND c.y = gs.y
    GROUP BY gs.y
);
GO

CREATE OR ALTER PROCEDURE dbo.DropDisc
    @GameId   INT,
    @ColumnNo TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ColumnNo < 1 OR @ColumnNo > 7
        THROW 50001, 'Column is out of range.', 1;

    DECLARE @Height TINYINT;
    SELECT @Height = COUNT(*) FROM dbo.Moves WHERE GameId = @GameId AND ColumnNo = @ColumnNo;
    IF @Height >= 6
        THROW 50002, 'Column is full.', 1;

    DECLARE @NextTurn INT;
    SELECT @NextTurn = COALESCE(MAX(TurnNo), 0) + 1 FROM dbo.Moves WHERE GameId = @GameId;

    INSERT INTO dbo.Moves (GameId, TurnNo, Player, ColumnNo)
    VALUES (@GameId, @NextTurn, CASE WHEN @NextTurn % 2 = 1 THEN 'X' ELSE 'O' END, @ColumnNo);
END;
GO
