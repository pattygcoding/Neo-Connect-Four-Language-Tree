program ConnectFour;

{$MODE OBJFPC}

const
    Rows = 6;
    Cols = 7;
    EmptyCell = '.';
    Players: array[1..2] of Char = ('X', 'O');
    Header = '=== Connect Four ===';
    Rules = 'Get four of your pieces in a row to win. Columns are numbered 1-7.';
    MaxValue = 9223372036854775807;

type
    TBoard = array[0..Rows - 1, 0..Cols - 1] of Char;

var
    Board: TBoard;

function IsSpace(Ch: Char): Boolean;
begin
    IsSpace := (Ch = ' ') or (Ch = #9) or (Ch = #10) or (Ch = #11) or (Ch = #12) or (Ch = #13);
end;

function Trimmed(const Text: string): string;
var
    First: Integer;
    Last: Integer;
begin
    First := 1;
    Last := Length(Text);
    while First <= Last do
    begin
        if not IsSpace(Text[First]) then
            Break;
        First := First + 1;
    end;
    while Last >= First do
    begin
        if not IsSpace(Text[Last]) then
            Break;
        Last := Last - 1;
    end;
    if First > Last then
        Trimmed := ''
    else
        Trimmed := Copy(Text, First, Last - First + 1);
end;

function NewBoard: TBoard;
var
    Row: Integer;
    Column: Integer;
begin
    for Row := 0 to Rows - 1 do
        for Column := 0 to Cols - 1 do
            NewBoard[Row, Column] := EmptyCell;
end;

function LowestEmptyRow(Column: Integer): Integer;
var
    Row: Integer;
begin
    LowestEmptyRow := -1;
    for Row := 0 to Rows - 1 do
        if Board[Row, Column] = EmptyCell then
        begin
            LowestEmptyRow := Row;
            Exit;
        end;
end;

function RunMatches(Player: Char; StartRow, StartColumn, RowStep, ColumnStep: Integer): Boolean;
var
    Step: Integer;
    Row: Integer;
    Column: Integer;
begin
    RunMatches := False;
    for Step := 0 to 3 do
    begin
        Row := StartRow + Step * RowStep;
        Column := StartColumn + Step * ColumnStep;
        if (Row < 0) or (Row >= Rows) or (Column < 0) or (Column >= Cols) then
            Exit;
        if Board[Row, Column] <> Player then
            Exit;
    end;
    RunMatches := True;
end;

function HasFour(Player: Char): Boolean;
var
    Row: Integer;
    Column: Integer;
begin
    HasFour := False;
    for Row := 0 to Rows - 1 do
        for Column := 0 to Cols - 1 do
            if RunMatches(Player, Row, Column, 0, 1) or
                RunMatches(Player, Row, Column, 1, 0) or
                RunMatches(Player, Row, Column, 1, 1) or
                RunMatches(Player, Row, Column, 1, -1) then
            begin
                HasFour := True;
                Exit;
            end;
end;

procedure PrintBorder;
var
    Index: Integer;
begin
    Write('+');
    for Index := 1 to Cols * 2 - 1 do
        Write('-');
    Writeln('+');
end;

procedure PrintBoard;
var
    Row: Integer;
    Column: Integer;
begin
    Write(' ');
    for Column := 1 to Cols do
    begin
        if Column > 1 then
            Write(' ');
        Write(Column);
    end;
    Writeln;
    PrintBorder;
    for Row := Rows - 1 downto 0 do
    begin
        Write('|');
        for Column := 0 to Cols - 1 do
        begin
            if Column > 0 then
                Write(' ');
            Write(Board[Row, Column]);
        end;
        Writeln('|');
    end;
    PrintBorder;
end;

function IsWholeNumber(const Text: string): Boolean;
var
    First: Integer;
    Index: Integer;
begin
    IsWholeNumber := False;
    if Length(Text) = 0 then
        Exit;
    First := 1;
    if (Text[1] = '+') or (Text[1] = '-') then
        First := 2;
    if First > Length(Text) then
        Exit;
    for Index := First to Length(Text) do
        if (Text[Index] < '0') or (Text[Index] > '9') then
            Exit;
    IsWholeNumber := True;
end;

function ValueOf(const Text: string): Int64;
var
    First: Integer;
    Index: Integer;
    Negative: Boolean;
    Digit: Int64;
begin
    Negative := False;
    First := 1;
    if (Length(Text) > 0) and ((Text[1] = '-') or (Text[1] = '+')) then
    begin
        Negative := Text[1] = '-';
        First := 2;
    end;
    ValueOf := 0;
    for Index := First to Length(Text) do
    begin
        Digit := Ord(Text[Index]) - Ord('0');
        if ValueOf > (MaxValue - Digit) div 10 then
        begin
            ValueOf := MaxValue;
            Exit;
        end;
        ValueOf := ValueOf * 10 + Digit;
    end;
    if Negative then
        ValueOf := -ValueOf;
end;

function AskColumn(Player: Char): Integer;
var
    Line: string;
    Token: string;
    Value: Int64;
begin
    while True do
    begin
        Write('Player ', Player, ', choose a column (1-7): ');
        Flush(Output);
        if Eof(Input) then
        begin
            Writeln;
            Writeln('Input closed. Goodbye.');
            AskColumn := -1;
            Exit;
        end;
        Readln(Line);
        Token := Trimmed(Line);
        if Length(Token) = 0 then
        begin
            Writeln;
            Writeln('Invalid input: no column entered.');
        end
        else if not IsWholeNumber(Token) then
        begin
            Writeln;
            Writeln('Invalid input: "', Token, '" is not a whole number.');
        end
        else
        begin
            Value := ValueOf(Token);
            if (Value < 1) or (Value > Cols) then
            begin
                Writeln;
                Writeln('Invalid input: "', Token, '" is out of range (1-7).');
            end
            else if LowestEmptyRow(Value - 1) < 0 then
            begin
                Writeln;
                Writeln('Column ', Value, ' is full.');
            end
            else
            begin
                AskColumn := Value - 1;
                Exit;
            end;
        end;
    end;
end;

procedure Play;
var
    PlayerIndex: Integer;
    Moves: Integer;
    Player: Char;
    Column: Integer;
    Row: Integer;
begin
    PlayerIndex := 0;
    Moves := 0;
    while True do
    begin
        Player := Players[PlayerIndex + 1];
        Column := AskColumn(Player);
        if Column < 0 then
            Break;
        Row := LowestEmptyRow(Column);
        Board[Row, Column] := Player;
        Moves := Moves + 1;
        Writeln;
        PrintBoard;
        if HasFour(Player) then
        begin
            Writeln('Player ', Player, ' wins!');
            Break;
        end;
        if Moves = Rows * Cols then
        begin
            Writeln('It''s a tie!');
            Break;
        end;
        PlayerIndex := 1 - PlayerIndex;
    end;
end;

begin
    Board := NewBoard;
    Writeln(Header);
    Writeln(Rules);
    Writeln;
    PrintBoard;
    Play;
end.
