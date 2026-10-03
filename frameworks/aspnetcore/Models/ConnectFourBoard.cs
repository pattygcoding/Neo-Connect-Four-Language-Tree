using System.Globalization;
using System.Linq;

namespace ConnectFour.Models;

public class ConnectFourBoard
{
    public const int Rows = 6;
    public const int Columns = 7;
    private const char Empty = '.';
    private const int LineLength = 4;
    private static readonly char[] Players = { 'X', 'O' };
    private static readonly (int Row, int Column)[] Directions = { (0, 1), (1, 0), (1, 1), (1, -1) };

    // Every (row, column) pair, row-major, so the rules below can be written as queries.
    private static readonly (int Row, int Column)[] Positions =
        (from row in Enumerable.Range(0, Rows)
         from column in Enumerable.Range(0, Columns)
         select (row, column)).ToArray();

    private readonly char[,] _cells = new char[Rows, Columns];
    private int _moves;

    public ConnectFourBoard()
    {
        foreach (var (row, column) in Positions)
        {
            _cells[row, column] = Empty;
        }
    }

    public static IEnumerable<int> TopDownRows => Enumerable.Range(0, Rows).Reverse();

    public static IEnumerable<int> ColumnIndexes => Enumerable.Range(0, Columns);

    public char CurrentPlayer => Players[_moves % Players.Length];

    public bool IsOver => Winner() != Empty || _moves == Rows * Columns;

    public char Winner() => Players.FirstOrDefault(HasLine, Empty);

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

    public string Serialize() =>
        string.Format(CultureInfo.InvariantCulture, "{0}:{1}", _moves, new string(_cells.Cast<char>().ToArray()));

    public static ConnectFourBoard Deserialize(string state)
    {
        var board = new ConnectFourBoard();
        var separator = state.IndexOf(':');
        if (separator < 0)
        {
            return board;
        }

        board._moves = int.Parse(state[..separator], CultureInfo.InvariantCulture);
        foreach (var (cell, (row, column)) in state[(separator + 1)..].Zip(Positions))
        {
            board._cells[row, column] = cell;
        }
        return board;
    }

    private int LowestEmptyRow(int column) =>
        Enumerable.Range(0, Rows)
            .Where(row => _cells[row, column] == Empty)
            .DefaultIfEmpty(-1)
            .First();

    private bool HasLine(char player) =>
        Positions.Any(position => _cells[position.Row, position.Column] == player
            && Directions.Any(direction => Enumerable.Range(1, LineLength - 1).All(step =>
                Matches(position.Row + direction.Row * step, position.Column + direction.Column * step, player))));

    private bool Matches(int row, int column, char player) =>
        row >= 0 && row < Rows && column >= 0 && column < Columns && _cells[row, column] == player;
}
