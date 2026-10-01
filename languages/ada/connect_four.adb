with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO;
with Ada.Text_IO; use Ada.Text_IO;

procedure Connect_Four is
    use Ada.Strings.Unbounded;

    Rows : constant := 6;
    Cols : constant := 7;
    Empty_Cell : constant Character := '.';
    Players : constant String (1 .. 2) := "XO";

    Max_Value : constant Long_Long_Integer := Long_Long_Integer'Last;

    type Board_Type is array (0 .. Rows - 1, 0 .. Cols - 1) of Character;
    Board : Board_Type;

    function Is_Space (Ch : Character) return Boolean is
    begin
        return Ch = ' '
            or else Ch = Ada.Characters.Latin_1.HT
            or else Ch = Ada.Characters.Latin_1.LF
            or else Ch = Ada.Characters.Latin_1.VT
            or else Ch = Ada.Characters.Latin_1.FF
            or else Ch = Ada.Characters.Latin_1.CR;
    end Is_Space;

    function Trimmed (Text : String) return String is
        First : Integer := Text'First;
        Last : Integer := Text'Last;
    begin
        while First <= Last and then Is_Space (Text (First)) loop
            First := First + 1;
        end loop;
        while Last >= First and then Is_Space (Text (Last)) loop
            Last := Last - 1;
        end loop;
        return Text (First .. Last);
    end Trimmed;

    function Image_Of (Value : Long_Long_Integer) return String is
        Text : constant String := Long_Long_Integer'Image (Value);
    begin
        if Text (Text'First) = ' ' then
            return Text (Text'First + 1 .. Text'Last);
        end if;
        return Text;
    end Image_Of;

    function New_Board return Board_Type is
        Result : Board_Type;
    begin
        for Row in Result'Range (1) loop
            for Column in Result'Range (2) loop
                Result (Row, Column) := Empty_Cell;
            end loop;
        end loop;
        return Result;
    end New_Board;

    function Lowest_Empty_Row (Column : Integer) return Integer is
    begin
        for Row in 0 .. Rows - 1 loop
            if Board (Row, Column) = Empty_Cell then
                return Row;
            end if;
        end loop;
        return -1;
    end Lowest_Empty_Row;

    procedure Print_Border is
    begin
        Put ("+");
        for Index in 1 .. Cols * 2 - 1 loop
            Put ("-");
        end loop;
        Put_Line ("+");
    end Print_Border;

    procedure Print_Board is
    begin
        Put (" ");
        for Column in 1 .. Cols loop
            if Column > 1 then
                Put (" ");
            end if;
            Put (Image_Of (Long_Long_Integer (Column)));
        end loop;
        New_Line;
        Print_Border;
        for Row in reverse 0 .. Rows - 1 loop
            Put ("|");
            for Column in 0 .. Cols - 1 loop
                if Column > 0 then
                    Put (" ");
                end if;
                Put (Board (Row, Column));
            end loop;
            Put_Line ("|");
        end loop;
        Print_Border;
    end Print_Board;

    function Run_Matches
        (Player : Character;
        Start_Row : Integer;
        Start_Column : Integer;
        Row_Step : Integer;
        Column_Step : Integer) return Boolean
    is
        Row : Integer;
        Column : Integer;
    begin
        for Step in 0 .. 3 loop
            Row := Start_Row + Step * Row_Step;
            Column := Start_Column + Step * Column_Step;
            if Row < 0 or else Row >= Rows or else Column < 0 or else Column >= Cols then
                return False;
            end if;
            if Board (Row, Column) /= Player then
                return False;
            end if;
        end loop;
        return True;
    end Run_Matches;

    function Has_Four (Player : Character) return Boolean is
    begin
        for Row in 0 .. Rows - 1 loop
            for Column in 0 .. Cols - 1 loop
                if Run_Matches (Player, Row, Column, 0, 1)
                    or else Run_Matches (Player, Row, Column, 1, 0)
                    or else Run_Matches (Player, Row, Column, 1, 1)
                    or else Run_Matches (Player, Row, Column, 1, -1)
                then
                    return True;
                end if;
            end loop;
        end loop;
        return False;
    end Has_Four;

    function Has_Sign (Text : String) return Boolean is
    begin
        return Text'Length > 0
            and then (Text (Text'First) = '+' or else Text (Text'First) = '-');
    end Has_Sign;

    function Is_Whole_Number (Text : String) return Boolean is
        First : Integer := Text'First;
    begin
        if Has_Sign (Text) then
            First := First + 1;
        end if;
        if First > Text'Last then
            return False;
        end if;
        for Index in First .. Text'Last loop
            if Text (Index) not in '0' .. '9' then
                return False;
            end if;
        end loop;
        return True;
    end Is_Whole_Number;

    function Value_Of (Text : String) return Long_Long_Integer is
        First : Integer := Text'First;
        Negative : Boolean := False;
        Value : Long_Long_Integer := 0;
        Digit : Long_Long_Integer;
    begin
        if Text (Text'First) = '-' then
            Negative := True;
            First := First + 1;
        elsif Text (Text'First) = '+' then
            First := First + 1;
        end if;
        for Index in First .. Text'Last loop
            Digit := Long_Long_Integer (Character'Pos (Text (Index)) - Character'Pos ('0'));
            if Value > (Max_Value - Digit) / 10 then
                Value := Max_Value;
                exit;
            end if;
            Value := Value * 10 + Digit;
        end loop;
        if Negative then
            return -Value;
        end if;
        return Value;
    end Value_Of;

    function Ask_Column (Player : Character) return Integer is
        Line : Unbounded_String;
        Token : Unbounded_String;
        Value : Long_Long_Integer;
    begin
        loop
            Put ("Player ");
            Put (Player);
            Put (", choose a column (1-7): ");
            Flush (Standard_Output);
            begin
                Line := Ada.Text_IO.Unbounded_IO.Get_Line;
            exception
                when End_Error =>
                    New_Line;
                    Put_Line ("Input closed. Goodbye.");
                    return -1;
            end;
            Token := To_Unbounded_String (Trimmed (To_String (Line)));
            if Length (Token) = 0 then
                New_Line;
                Put_Line ("Invalid input: no column entered.");
            elsif not Is_Whole_Number (To_String (Token)) then
                New_Line;
                Put_Line
                    ("Invalid input: " & '"' & To_String (Token) & '"'
                        & " is not a whole number.");
            else
                Value := Value_Of (To_String (Token));
                if Value < 1 or else Value > Cols then
                    New_Line;
                    Put_Line
                        ("Invalid input: " & '"' & To_String (Token) & '"'
                            & " is out of range (1-7).");
                elsif Lowest_Empty_Row (Integer (Value) - 1) < 0 then
                    New_Line;
                    Put_Line ("Column " & Image_Of (Value) & " is full.");
                else
                    return Integer (Value) - 1;
                end if;
            end if;
        end loop;
    end Ask_Column;

begin
    Board := New_Board;
    Put ("=== Connect Four ===");
    New_Line;
    Put_Line ("Get four of your pieces in a row to win. Columns are numbered 1-7.");
    New_Line;
    Print_Board;
    declare
        Player_Index : Integer := 0;
        Moves : Integer := 0;
        Player : Character;
        Column : Integer;
        Row : Integer;
    begin
        loop
            Player := Players (Player_Index + 1);
            Column := Ask_Column (Player);
            exit when Column < 0;
            Row := Lowest_Empty_Row (Column);
            Board (Row, Column) := Player;
            Moves := Moves + 1;
            New_Line;
            Print_Board;
            if Has_Four (Player) then
                Put ("Player ");
                Put (Player);
                Put_Line (" wins!");
                exit;
            end if;
            if Moves = Rows * Cols then
                Put_Line ("It's a tie!");
                exit;
            end if;
            Player_Index := 1 - Player_Index;
        end loop;
    end;
end Connect_Four;
