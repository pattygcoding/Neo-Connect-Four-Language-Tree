using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace ConnectFour;

public partial class MainWindow : Window
{
    private static readonly Brush EmptySlot = new SolidColorBrush(Color.FromRgb(0x0B, 0x12, 0x20));
    private static readonly Brush RedDisc = new SolidColorBrush(Color.FromRgb(0xEF, 0x44, 0x44));
    private static readonly Brush YellowDisc = new SolidColorBrush(Color.FromRgb(0xFA, 0xCC, 0x15));

    private ConnectFourBoard _board = new();

    public MainWindow()
    {
        InitializeComponent();
        Render();
    }

    private void OnColumnClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string tag }
            && int.TryParse(tag, out var column)
            && !_board.IsOver
            && !_board.IsFull(column - 1))
        {
            _board.Drop(column - 1);
            Render();
        }
    }

    private void OnResetClicked(object sender, RoutedEventArgs e)
    {
        _board = new ConnectFourBoard();
        Render();
    }

    private void Render()
    {
        StatusLabel.Text = Status();
        BoardGrid.Children.Clear();

        for (var row = ConnectFourBoard.Rows - 1; row >= 0; row--)
        {
            for (var column = 0; column < ConnectFourBoard.Columns; column++)
            {
                BoardGrid.Children.Add(new Border
                {
                    Background = BrushFor(_board.Cell(row, column)),
                    CornerRadius = new CornerRadius(20),
                    Margin = new Thickness(3),
                });
            }
        }
    }

    private static Brush BrushFor(char cell) => cell switch
    {
        'X' => RedDisc,
        'O' => YellowDisc,
        _ => EmptySlot,
    };

    private string Status() => _board.Winner() != ConnectFourBoard.Empty
        ? $"Player {_board.Winner()} wins!"
        : _board.IsOver
            ? "It's a tie!"
            : $"Player {_board.CurrentPlayer}, choose a column.";
}
