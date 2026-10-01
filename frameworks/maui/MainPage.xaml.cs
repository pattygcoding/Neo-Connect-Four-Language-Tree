namespace ConnectFour;

public partial class MainPage : ContentPage
{
    private ConnectFourBoard _board = new();

    public MainPage()
    {
        InitializeComponent();
        Render();
    }

    private void OnColumnClicked(object sender, EventArgs e)
    {
        if (sender is not Button button || !int.TryParse(button.Text, out var column))
        {
            return;
        }

        if (!_board.IsOver && !_board.IsFull(column - 1))
        {
            _board.Drop(column - 1);
        }

        Render();
    }

    private void OnResetClicked(object sender, EventArgs e)
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
                BoardGrid.Add(
                    new Label
                    {
                        Text = _board.Cell(row, column).ToString(),
                        HorizontalTextAlignment = TextAlignment.Center,
                        VerticalTextAlignment = TextAlignment.Center,
                    },
                    column,
                    ConnectFourBoard.Rows - 1 - row);
            }
        }
    }

    private string Status() => _board.Winner() != '.'
        ? $"Player {_board.Winner()} wins!"
        : _board.IsOver
            ? "It's a tie!"
            : $"Player {_board.CurrentPlayer}, choose a column.";
}
