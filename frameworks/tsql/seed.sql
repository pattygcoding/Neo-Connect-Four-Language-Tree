INSERT INTO dbo.Games (Player) VALUES (N'demo');
GO

EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 1;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 1;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 2;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 2;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 3;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 3;
EXEC dbo.DropDisc @GameId = 1, @ColumnNo = 4;
GO

SELECT * FROM dbo.fn_Board (1) ORDER BY RowIndex DESC;
SELECT dbo.fn_Winner (1) AS Winner;
GO
