using System;
using System.IO;
using System.Text;

internal static class ConnectFour
{
    private const int Rows = 6;
    private const int Cols = 7;
    private const char Empty = '.';
    private static readonly char[] Players = { 'X', 'O' };
    private const string Header =
        "=== Connect Four ===\n" +
        "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";
    private static readonly string Border = MakeBorder();
    private static readonly string Labels = MakeLabels();

    private static string MakeBorder()
    {
        var b = new StringBuilder();
        b.Append('+');
        for (int i = 0; i < Cols * 2 - 1; i++)
        {
            b.Append('-');
        }
        b.Append('+');
        return b.ToString();
    }

    private static string MakeLabels()
    {
        var b = new StringBuilder();
        b.Append(' ');
        for (int c = 1; c <= Cols; c++)
        {
            if (c > 1)
            {
                b.Append(' ');
            }
            b.Append((char)('0' + c));
        }
        return b.ToString();
    }

    private static string Render(char[,] board)
    {
        var b = new StringBuilder();
        b.Append(Labels).Append('\n');
        b.Append(Border).Append('\n');
        for (int r = Rows - 1; r >= 0; r--)
        {
            b.Append('|');
            for (int c = 0; c < Cols; c++)
            {
                if (c > 0)
                {
                    b.Append(' ');
                }
                b.Append(board[r, c]);
            }
            b.Append("|\n");
        }
        b.Append(Border);
        return b.ToString();
    }

    private static int LowestEmptyRow(char[,] board, int col)
    {
        for (int r = 0; r < Rows; r++)
        {
            if (board[r, col] == Empty)
            {
                return r;
            }
        }
        return -1;
    }

    private static bool HasFour(char[,] board, char p)
    {
        for (int r = 0; r < Rows; r++)
        {
            for (int c = 0; c + 3 < Cols; c++)
            {
                if (board[r, c] == p && board[r, c + 1] == p
                    && board[r, c + 2] == p && board[r, c + 3] == p)
                {
                    return true;
                }
            }
        }
        for (int r = 0; r + 3 < Rows; r++)
        {
            for (int c = 0; c < Cols; c++)
            {
                if (board[r, c] == p && board[r + 1, c] == p
                    && board[r + 2, c] == p && board[r + 3, c] == p)
                {
                    return true;
                }
            }
        }
        for (int r = 0; r + 3 < Rows; r++)
        {
            for (int c = 0; c + 3 < Cols; c++)
            {
                if (board[r, c] == p && board[r + 1, c + 1] == p
                    && board[r + 2, c + 2] == p && board[r + 3, c + 3] == p)
                {
                    return true;
                }
            }
        }
        for (int r = 3; r < Rows; r++)
        {
            for (int c = 0; c + 3 < Cols; c++)
            {
                if (board[r, c] == p && board[r - 1, c + 1] == p
                    && board[r - 2, c + 2] == p && board[r - 3, c + 3] == p)
                {
                    return true;
                }
            }
        }
        return false;
    }

    private static bool IsWholeNumber(string token)
    {
        string t = token;
        if (t.StartsWith("+", StringComparison.Ordinal)
            || t.StartsWith("-", StringComparison.Ordinal))
        {
            t = t.Substring(1);
        }
        if (t.Length == 0)
        {
            return false;
        }
        foreach (char ch in t)
        {
            if (ch < '0' || ch > '9')
            {
                return false;
            }
        }
        return true;
    }

    private static int AskColumn(char[,] board, char player)
    {
        TextWriter output = Console.Out;
        TextReader input = Console.In;
        while (true)
        {
            output.Write("Player " + player + ", choose a column (1-7): ");
            output.Flush();
            string raw = input.ReadLine();
            if (raw == null)
            {
                output.Write("\nInput closed. Goodbye.\n");
                return -1;
            }
            string token = raw.Trim();
            string message;
            if (token.Length == 0)
            {
                message = "Invalid input: no column entered.";
            }
            else if (!IsWholeNumber(token))
            {
                message = "Invalid input: \"" + token + "\" is not a whole number.";
            }
            else
            {
                long value;
                if (!long.TryParse(token, out value))
                {
                    value = long.MaxValue;
                }
                if (value < 1 || value > Cols)
                {
                    message = "Invalid input: \"" + token + "\" is out of range (1-7).";
                }
                else if (LowestEmptyRow(board, (int)value - 1) < 0)
                {
                    message = "Column " + value + " is full.";
                }
                else
                {
                    return (int)value - 1;
                }
            }
            output.Write("\n" + message + "\n");
            output.Flush();
        }
    }

    private static void Main()
    {
        var board = new char[Rows, Cols];
        for (int r = 0; r < Rows; r++)
        {
            for (int c = 0; c < Cols; c++)
            {
                board[r, c] = Empty;
            }
        }
        Console.Out.Write(Header + "\n" + Render(board) + "\n");
        Console.Out.Flush();

        int moves = 0;
        int playerIndex = 0;
        while (true)
        {
            char player = Players[playerIndex];
            int column = AskColumn(board, player);
            if (column < 0)
            {
                return;
            }
            board[LowestEmptyRow(board, column), column] = player;
            moves++;
            Console.Out.Write("\n" + Render(board) + "\n");
            if (HasFour(board, player))
            {
                Console.Out.Write("Player " + player + " wins!\n");
                return;
            }
            if (moves == Rows * Cols)
            {
                Console.Out.Write("It's a tie!\n");
                return;
            }
            playerIndex = 1 - playerIndex;
        }
    }
}
