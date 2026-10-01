Imports System.Windows
Imports System.Windows.Controls
Imports System.Windows.Media

Partial Public Class MainWindow

    Private Shared ReadOnly EmptySlot As Brush = New SolidColorBrush(Color.FromRgb(&HB, &H12, &H20))
    Private Shared ReadOnly RedDisc As Brush = New SolidColorBrush(Color.FromRgb(&HEF, &H44, &H44))
    Private Shared ReadOnly YellowDisc As Brush = New SolidColorBrush(Color.FromRgb(&HFA, &HCC, &H15))

    Private _board As New ConnectFourBoard()

    Public Sub New()
        InitializeComponent()
        Render()
    End Sub

    Private Sub OnColumnClicked(sender As Object, e As RoutedEventArgs)
        Dim button = TryCast(sender, Button)
        Dim column As Integer

        If button IsNot Nothing AndAlso Integer.TryParse(CStr(button.Tag), column) AndAlso
           Not _board.IsOver AndAlso Not _board.IsFull(column - 1) Then
            _board.Drop(column - 1)
            Render()
        End If
    End Sub

    Private Sub OnResetClicked(sender As Object, e As RoutedEventArgs)
        _board = New ConnectFourBoard()
        Render()
    End Sub

    Private Sub Render()
        StatusLabel.Text = Status()
        BoardGrid.Children.Clear()

        For row As Integer = ConnectFourBoard.Rows - 1 To 0 Step -1
            For column As Integer = 0 To ConnectFourBoard.Columns - 1
                BoardGrid.Children.Add(New Border With {
                    .Background = BrushFor(_board.Cell(row, column)),
                    .CornerRadius = New CornerRadius(20),
                    .Margin = New Thickness(3)
                })
            Next
        Next
    End Sub

    Private Shared Function BrushFor(cell As Char) As Brush
        If cell = "X"c Then Return RedDisc
        If cell = "O"c Then Return YellowDisc
        Return EmptySlot
    End Function

    Private Function Status() As String
        If _board.Winner() <> ConnectFourBoard.Empty Then
            Return $"Player {_board.Winner()} wins!"
        ElseIf _board.IsOver Then
            Return "It's a tie!"
        Else
            Return $"Player {_board.CurrentPlayer}, choose a column."
        End If
    End Function
End Class
