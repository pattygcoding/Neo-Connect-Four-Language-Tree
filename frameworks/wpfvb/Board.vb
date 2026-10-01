Public Class ConnectFourBoard

    Public Const Rows As Integer = 6
    Public Const Columns As Integer = 7
    Public Const Empty As Char = "."c

    Private Shared ReadOnly Players As Char() = {"X"c, "O"c}
    Private Shared ReadOnly Directions As Integer()() = {
        New Integer() {0, 1},
        New Integer() {1, 0},
        New Integer() {1, 1},
        New Integer() {1, -1}
    }

    Private ReadOnly _cells(Rows - 1, Columns - 1) As Char

    Public Sub New()
        For row As Integer = 0 To Rows - 1
            For column As Integer = 0 To Columns - 1
                _cells(row, column) = Empty
            Next
        Next
    End Sub

    Public Property Moves As Integer

    Public ReadOnly Property CurrentPlayer As Char
        Get
            Return Players(Moves Mod Players.Length)
        End Get
    End Property

    Public ReadOnly Property IsOver As Boolean
        Get
            Return Winner() <> Empty OrElse Moves = Rows * Columns
        End Get
    End Property

    Public Function Cell(row As Integer, column As Integer) As Char
        Return _cells(row, column)
    End Function

    Public Function IsFull(column As Integer) As Boolean
        Return LowestEmptyRow(column) < 0
    End Function

    Public Function Drop(column As Integer) As Boolean
        Dim row As Integer = LowestEmptyRow(column)
        If row < 0 Then
            Return False
        End If

        _cells(row, column) = CurrentPlayer
        Moves += 1
        Return True
    End Function

    Public Function Winner() As Char
        For Each player As Char In Players
            For row As Integer = 0 To Rows - 1
                For column As Integer = 0 To Columns - 1
                    If _cells(row, column) <> player Then
                        Continue For
                    End If

                    For Each direction As Integer() In Directions
                        If Matches(row + direction(0), column + direction(1), player) AndAlso
                           Matches(row + direction(0) * 2, column + direction(1) * 2, player) AndAlso
                           Matches(row + direction(0) * 3, column + direction(1) * 3, player) Then
                            Return player
                        End If
                    Next
                Next
            Next
        Next

        Return Empty
    End Function

    Private Function LowestEmptyRow(column As Integer) As Integer
        For row As Integer = 0 To Rows - 1
            If _cells(row, column) = Empty Then
                Return row
            End If
        Next

        Return -1
    End Function

    Private Function Matches(row As Integer, column As Integer, player As Char) As Boolean
        Return row >= 0 AndAlso row < Rows AndAlso column >= 0 AndAlso column < Columns AndAlso _cells(row, column) = player
    End Function
End Class
