using Avalonia;
using Avalonia.Controls;
using Avalonia.Layout;
using Avalonia.Media;
using System;

namespace ConnectFour;

public partial class MainWindow : Window
{
    private readonly ConnectFourBoard _board = new();
    private readonly StackPanel _boardPanel = new() { Spacing = 4 };
    private readonly StackPanel _columnsPanel = new()
    {
        Orientation = Orientation.Horizontal,
        Spacing = 4,
    };

    public MainWindow()
    {
        InitializeComponent();

        BoardHost.Children.Add(_boardPanel);
        ColumnsHost.Children.Add(_columnsPanel);
        ResetButton.Click += (_, _) => Reset();
        Render();
    }

    private void Render()
    {
        StatusText.Text = _board.Winner is { } champion
            ? $"Player {champion} wins!"
            : _board.IsOver
                ? "It's a tie!"
                : $"Player {_board.CurrentPlayer}, choose a column.";

        _boardPanel.Children.Clear();
        for (int row = ConnectFourBoard.Rows - 1; row >= 0; row--)
        {
            var rowPanel = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 4,
            };

            for (int column = 0; column < ConnectFourBoard.Columns; column++)
            {
                string cell = _board[row, column];
                var border = new Border
                {
                    Width = 40,
                    Height = 40,
                    CornerRadius = new CornerRadius(20),
                    Background = DiscBrush(cell),
                    Child = new TextBlock
                    {
                        Text = cell,
                        HorizontalAlignment = HorizontalAlignment.Center,
                        VerticalAlignment = VerticalAlignment.Center,
                    },
                };
                rowPanel.Children.Add(border);
            }

            _boardPanel.Children.Add(rowPanel);
        }

        _columnsPanel.Children.Clear();
        for (int column = 0; column < ConnectFourBoard.Columns; column++)
        {
            int target = column;
            var button = new Button
            {
                Content = (column + 1).ToString(),
                IsEnabled = !_board.IsOver && !_board.IsFull(column),
            };
            button.Click += (_, _) =>
            {
                _board.Drop(target);
                Render();
            };
            _columnsPanel.Children.Add(button);
        }
    }

    private void Reset()
    {
        _board.Reset();
        Render();
    }

    private static IBrush DiscBrush(string cell) => cell switch
    {
        "X" => Brushes.Crimson,
        "O" => Brushes.Gold,
        _ => Brushes.DarkSlateGray,
    };
}
