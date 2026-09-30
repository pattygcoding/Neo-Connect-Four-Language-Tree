Imports System
Imports System.IO
Imports System.Text

Module ConnectFour
    Private Const Rows As Integer = 6
    Private Const Cols As Integer = 7
    Private Const Empty As Char = "."c
    Private ReadOnly Players As Char() = {"X"c, "O"c}
    Private Const Header As String =
        "=== Connect Four ===" & vbLf &
        "Get four of your pieces in a row to win. Columns are numbered 1-7." & vbLf
    Private ReadOnly Border As String = MakeBorder()
    Private ReadOnly Labels As String = MakeLabels()

    Private Function MakeBorder() As String
        Dim b As New StringBuilder()
        b.Append("+"c)
        For i As Integer = 1 To Cols * 2 - 1
            b.Append("-"c)
        Next
        b.Append("+"c)
        Return b.ToString()
    End Function

    Private Function MakeLabels() As String
        Dim b As New StringBuilder()
        b.Append(" "c)
        For c As Integer = 1 To Cols
            If c > 1 Then
                b.Append(" "c)
            End If
            b.Append(c)
        Next
        Return b.ToString()
    End Function

    Private Function Render(board(,) As Char) As String
        Dim b As New StringBuilder()
        b.Append(Labels).Append(vbLf)
        b.Append(Border).Append(vbLf)
        For r As Integer = Rows - 1 To 0 Step -1
            b.Append("|"c)
            For c As Integer = 0 To Cols - 1
                If c > 0 Then
                    b.Append(" "c)
                End If
                b.Append(board(r, c))
            Next
            b.Append("|").Append(vbLf)
        Next
        b.Append(Border)
        Return b.ToString()
    End Function

    Private Function LowestEmptyRow(board(,) As Char, col As Integer) As Integer
        For r As Integer = 0 To Rows - 1
            If board(r, col) = Empty Then
                Return r
            End If
        Next
        Return -1
    End Function

    Private Function HasFour(board(,) As Char, player As Char) As Boolean
        For r As Integer = 0 To Rows - 1
            For c As Integer = 0 To Cols - 4
                If board(r, c) = player AndAlso board(r, c + 1) = player AndAlso
                        board(r, c + 2) = player AndAlso board(r, c + 3) = player Then
                    Return True
                End If
            Next
        Next
        For r As Integer = 0 To Rows - 4
            For c As Integer = 0 To Cols - 1
                If board(r, c) = player AndAlso board(r + 1, c) = player AndAlso
                        board(r + 2, c) = player AndAlso board(r + 3, c) = player Then
                    Return True
                End If
            Next
        Next
        For r As Integer = 0 To Rows - 4
            For c As Integer = 0 To Cols - 4
                If board(r, c) = player AndAlso board(r + 1, c + 1) = player AndAlso
                        board(r + 2, c + 2) = player AndAlso board(r + 3, c + 3) = player Then
                    Return True
                End If
            Next
        Next
        For r As Integer = 3 To Rows - 1
            For c As Integer = 0 To Cols - 4
                If board(r, c) = player AndAlso board(r - 1, c + 1) = player AndAlso
                        board(r - 2, c + 2) = player AndAlso board(r - 3, c + 3) = player Then
                    Return True
                End If
            Next
        Next
        Return False
    End Function

    Private Function IsWholeNumber(token As String) As Boolean
        Dim body As String = token
        If body.StartsWith("+") OrElse body.StartsWith("-") Then
            body = body.Substring(1)
        End If
        If body.Length = 0 Then
            Return False
        End If
        For Each ch As Char In body
            If ch < "0"c OrElse ch > "9"c Then
                Return False
            End If
        Next
        Return True
    End Function

    Private Function AskColumn(board(,) As Char, player As Char) As Integer
        Dim output As TextWriter = Console.Out
        Dim input As TextReader = Console.In
        Do
            output.Write("Player " & player & ", choose a column (1-7): ")
            output.Flush()
            Dim raw As String = input.ReadLine()
            If raw Is Nothing Then
                output.Write(vbLf & "Input closed. Goodbye." & vbLf)
                Return -1
            End If
            Dim token As String = raw.Trim()
            Dim message As String
            If token.Length = 0 Then
                message = "Invalid input: no column entered."
            ElseIf Not IsWholeNumber(token) Then
                message = "Invalid input: """ & token & """ is not a whole number."
            Else
                Dim value As Long
                If Not Long.TryParse(token, value) Then
                    value = Long.MaxValue
                End If
                If value < 1 OrElse value > Cols Then
                    message = "Invalid input: """ & token & """ is out of range (1-7)."
                ElseIf LowestEmptyRow(board, CInt(value) - 1) < 0 Then
                    message = "Column " & value & " is full."
                Else
                    Return CInt(value) - 1
                End If
            End If
            output.Write(vbLf & message & vbLf)
            output.Flush()
        Loop
    End Function

    Sub Main()
        Dim board(Rows - 1, Cols - 1) As Char
        For r As Integer = 0 To Rows - 1
            For c As Integer = 0 To Cols - 1
                board(r, c) = Empty
            Next
        Next
        Console.Out.Write(Header & vbLf & Render(board) & vbLf)
        Console.Out.Flush()

        Dim moves As Integer = 0
        Dim playerIndex As Integer = 0
        Do
            Dim player As Char = Players(playerIndex)
            Dim column As Integer = AskColumn(board, player)
            If column < 0 Then
                Return
            End If
            board(LowestEmptyRow(board, column), column) = player
            moves += 1
            Console.Out.Write(vbLf & Render(board) & vbLf)
            If HasFour(board, player) Then
                Console.Out.Write("Player " & player & " wins!" & vbLf)
                Return
            End If
            If moves = Rows * Cols Then
                Console.Out.Write("It's a tie!" & vbLf)
                Return
            End If
            playerIndex = 1 - playerIndex
        Loop
    End Sub
End Module
