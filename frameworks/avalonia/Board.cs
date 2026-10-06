namespace ConnectFour;

public sealed class ConnectFourBoard
{
    public const int Rows = 6;
    public const int Columns = 7;
    public const string Empty = ".";

    private static readonly string[] Players = { "X", "O" };

    private static readonly (int Row, int Column)[] Directions =
    {
        (0, 1),
        (1, 0),
        (1, 1),
        (1, -1),
    };

    private readonly string[,] _cells = new string[Rows, Columns];

    public ConnectFourBoard()
    {
        for (int row = 0; row < Rows; row++)
        {
            for (int column = 0; column < Columns; column++)
            {
                _cells[row, column] = Empty;
            }
        }
    }

    public int Moves { get; private set; }

    public string this[int row, int column] => _cells[row, column];

    public string CurrentPlayer => Players[Moves % Players.Length];

    public string? Winner => Players.FirstOrDefault(HasLine);

    public bool IsOver => Winner is not null || Moves == Rows * Columns;

    public int LowestEmptyRow(int column)
    {
        for (int row = 0; row < Rows; row++)
        {
            if (_cells[row, column] == Empty)
            {
                return row;
            }
        }
        return -1;
    }

    public bool IsFull(int column) => LowestEmptyRow(column) < 0;

    public bool Drop(int column)
    {
        int row = LowestEmptyRow(column);
        if (row < 0)
        {
            return false;
        }
        _cells[row, column] = CurrentPlayer;
        Moves++;
        return true;
    }

    public void Reset()
    {
        for (int row = 0; row < Rows; row++)
        {
            for (int column = 0; column < Columns; column++)
            {
                _cells[row, column] = Empty;
            }
        }
        Moves = 0;
    }

    private bool HasLine(string player)
    {
        for (int row = 0; row < Rows; row++)
        {
            for (int column = 0; column < Columns; column++)
            {
                foreach ((int rowStep, int columnStep) in Directions)
                {
                    bool line = true;
                    for (int step = 1; step <= 3; step++)
                    {
                        if (!Matches(row + rowStep * step, column + columnStep * step, player))
                        {
                            line = false;
                            break;
                        }
                    }
                    if (line)
                    {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private bool Matches(int row, int column, string player)
    {
        return row >= 0
            && row < Rows
            && column >= 0
            && column < Columns
            && _cells[row, column] == player;
    }
}
