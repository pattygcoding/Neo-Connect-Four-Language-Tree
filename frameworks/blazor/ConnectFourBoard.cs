namespace ConnectFour;

public class ConnectFourBoard
{
    public const int Rows = 6;
    public const int Columns = 7;
    private const char Empty = '.';
    private static readonly char[] Players = { 'X', 'O' };
    private static readonly (int Row, int Column)[] Directions = { (0, 1), (1, 0), (1, 1), (1, -1) };

    private readonly char[,] _cells = new char[Rows, Columns];
    private int _moves;

    public ConnectFourBoard()
    {
        for (var row = 0; row < Rows; row++)
        {
            for (var column = 0; column < Columns; column++)
            {
                _cells[row, column] = Empty;
            }
        }
    }

    public char CurrentPlayer => Players[_moves % Players.Length];

    public char Winner()
    {
        foreach (var player in Players)
        {
            if (HasLine(player))
            {
                return player;
            }
        }
        return Empty;
    }

    public bool IsOver => Winner() != Empty || _moves == Rows * Columns;

    public bool IsFull(int column) => LowestEmptyRow(column) < 0;

    public bool Drop(int column)
    {
        var row = LowestEmptyRow(column);
        if (row < 0)
        {
            return false;
        }
        _cells[row, column] = CurrentPlayer;
        _moves++;
        return true;
    }

    public char Cell(int row, int column) => _cells[row, column];

    private int LowestEmptyRow(int column)
    {
        for (var row = 0; row < Rows; row++)
        {
            if (_cells[row, column] == Empty)
            {
                return row;
            }
        }
        return -1;
    }

    private bool HasLine(char player)
    {
        for (var row = 0; row < Rows; row++)
        {
            for (var column = 0; column < Columns; column++)
            {
                if (_cells[row, column] != player)
                {
                    continue;
                }
                foreach (var (rowStep, columnStep) in Directions)
                {
                    if (Matches(row + rowStep, column + columnStep, player)
                        && Matches(row + rowStep * 2, column + columnStep * 2, player)
                        && Matches(row + rowStep * 3, column + columnStep * 3, player))
                    {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private bool Matches(int row, int column, char player) =>
        row >= 0 && row < Rows && column >= 0 && column < Columns && _cells[row, column] == player;
}
