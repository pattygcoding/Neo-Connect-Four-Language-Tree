CREATE TABLE dbo.Games (
    GameId    INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Games PRIMARY KEY,
    Player    NVARCHAR(64)       NOT NULL,
    CreatedAt DATETIME2(0)       NOT NULL CONSTRAINT DF_Games_CreatedAt DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.Moves (
    MoveId   INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Moves PRIMARY KEY,
    GameId   INT                NOT NULL CONSTRAINT FK_Moves_Games REFERENCES dbo.Games (GameId),
    TurnNo   INT                NOT NULL,
    Player   CHAR(1)            NOT NULL,
    ColumnNo TINYINT            NOT NULL,
    CONSTRAINT UQ_Moves_Turn   UNIQUE (GameId, TurnNo),
    CONSTRAINT CK_Moves_Player CHECK (Player IN ('X', 'O')),
    CONSTRAINT CK_Moves_Column CHECK (ColumnNo BETWEEN 1 AND 7)
);
GO

CREATE INDEX IX_Moves_Game_Column ON dbo.Moves (GameId, ColumnNo, TurnNo);
GO

CREATE VIEW dbo.Cells
AS
    SELECT
        game_id = m.GameId,
        x = m.ColumnNo,
        y = ROW_NUMBER() OVER (PARTITION BY m.GameId, m.ColumnNo ORDER BY m.TurnNo),
        player = m.Player
    FROM dbo.Moves AS m;
GO
