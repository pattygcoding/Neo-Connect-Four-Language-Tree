players(0, 'X').
players(1, 'O').

header('=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n').

empty_board(Board) :-
    length(Board, 6),
    maplist(empty_row, Board).

empty_row(Row) :-
    length(Row, 7),
    maplist(=( '.' ), Row).

labels(Text) :-
    numlist(1, 7, Numbers),
    atomic_list_concat(Numbers, ' ', Body),
    atomic_list_concat([' ', Body], Text).

border(Text) :-
    length(Dashes, 13),
    maplist(=( '-' ), Dashes),
    atomic_list_concat(['+' | Dashes], Left),
    atomic_list_concat([Left, '+'], Text).

row_text(Row, Text) :-
    atomic_list_concat(Row, ' ', Inner),
    atomic_list_concat(['|', Inner, '|'], Text).

render(Board, Text) :-
    labels(LabelText),
    border(BorderText),
    reverse(Board, TopFirst),
    maplist(row_text, TopFirst, RowTexts),
    append([LabelText, BorderText], RowTexts, WithRows),
    append(WithRows, [BorderText], Lines),
    atomic_list_concat(Lines, '\n', Text).

cell(Board, Row, Col, Cell) :-
    nth0(Row, Board, Cells),
    nth0(Col, Cells, Cell).

lowest_empty_row(Board, Col, Index) :-
    lowest_empty_row(Board, Col, 0, Index).

lowest_empty_row([], _, _, -1).
lowest_empty_row([Cells | Rest], Col, Current, Index) :-
    nth0(Col, Cells, Cell),
    ( Cell == '.' ->
        Index = Current
    ;
        Next is Current + 1,
        lowest_empty_row(Rest, Col, Next, Index)
    ).

put(Board, Row, Col, Value, NewBoard) :-
    nth0(Row, Board, Cells, OtherRows),
    nth0(Col, Cells, _, OtherCells),
    nth0(Col, NewCells, Value, OtherCells),
    nth0(Row, NewBoard, NewCells, OtherRows).

has_four(Board, Player) :- four_horizontal(Board, Player).
has_four(Board, Player) :- four_vertical(Board, Player).
has_four(Board, Player) :- four_diagonal_up(Board, Player).
has_four(Board, Player) :- four_diagonal_down(Board, Player).

four_horizontal(Board, Player) :-
    between(0, 5, Row),
    between(0, 3, Col),
    cell(Board, Row, Col, Player),
    Col1 is Col + 1, cell(Board, Row, Col1, Player),
    Col2 is Col + 2, cell(Board, Row, Col2, Player),
    Col3 is Col + 3, cell(Board, Row, Col3, Player).

four_vertical(Board, Player) :-
    between(0, 2, Row),
    between(0, 6, Col),
    cell(Board, Row, Col, Player),
    Row1 is Row + 1, cell(Board, Row1, Col, Player),
    Row2 is Row + 2, cell(Board, Row2, Col, Player),
    Row3 is Row + 3, cell(Board, Row3, Col, Player).

four_diagonal_up(Board, Player) :-
    between(0, 2, Row),
    between(0, 3, Col),
    cell(Board, Row, Col, Player),
    Row1 is Row + 1, Col1 is Col + 1, cell(Board, Row1, Col1, Player),
    Row2 is Row + 2, Col2 is Col + 2, cell(Board, Row2, Col2, Player),
    Row3 is Row + 3, Col3 is Col + 3, cell(Board, Row3, Col3, Player).

four_diagonal_down(Board, Player) :-
    between(3, 5, Row),
    between(0, 3, Col),
    cell(Board, Row, Col, Player),
    Row1 is Row - 1, Col1 is Col + 1, cell(Board, Row1, Col1, Player),
    Row2 is Row - 2, Col2 is Col + 2, cell(Board, Row2, Col2, Player),
    Row3 is Row - 3, Col3 is Col + 3, cell(Board, Row3, Col3, Player).

layout_code(32).
layout_code(9).
layout_code(10).
layout_code(13).
layout_code(11).
layout_code(12).

drop_leading_layout([C | Cs], Rest) :-
    layout_code(C),
    !,
    drop_leading_layout(Cs, Rest).
drop_leading_layout(Codes, Codes).

trim_codes(Codes, Trimmed) :-
    drop_leading_layout(Codes, Rest),
    reverse(Rest, Reversed),
    drop_leading_layout(Reversed, ReversedRest),
    reverse(ReversedRest, Trimmed).

all_digits([]).
all_digits([C | Cs]) :-
    C >= 0'0,
    C =< 0'9,
    all_digits(Cs).

whole_number([First | Rest], Sign, Digits) :-
    ( First =:= 0'+ ->
        Sign = 1,
        Digits = Rest
    ; First =:= 0'- ->
        Sign = -1,
        Digits = Rest
    ;
        Sign = 1,
        Digits = [First | Rest]
    ),
    Digits = [ _ | _ ],
    all_digits(Digits).

digits_value(Digits, Sign, Value) :-
    number_codes(Number, Digits),
    Value is Sign * Number.

report(Message) :-
    nl,
    write(Message),
    nl,
    flush_output.

ask_column(Board, Player, Column) :-
    format("Player ~w, choose a column (1-7): ", [Player]),
    flush_output,
    read_line_to_codes(user_input, Raw),
    ( Raw == end_of_file ->
        format("\nInput closed. Goodbye.\n"),
        flush_output,
        Column = eof
    ;
        trim_codes(Raw, Token),
        handle_token(Board, Player, Token, Column)
    ).

handle_token(Board, Player, Token, Column) :-
    ( Token == [] ->
        report('Invalid input: no column entered.'),
        ask_column(Board, Player, Column)
    ; whole_number(Token, Sign, Digits) ->
        digits_value(Digits, Sign, Value),
        ( ( Value < 1 ; Value > 7 ) ->
            format("\nInvalid input: \"~s\" is out of range (1-7).\n", [Token]),
            flush_output,
            ask_column(Board, Player, Column)
        ;
            Column0 is Value - 1,
            lowest_empty_row(Board, Column0, RowIndex),
            ( RowIndex =:= -1 ->
                format("\nColumn ~w is full.\n", [Value]),
                flush_output,
                ask_column(Board, Player, Column)
            ;
                Column = Column0
            )
        )
    ;
        format("\nInvalid input: \"~s\" is not a whole number.\n", [Token]),
        flush_output,
        ask_column(Board, Player, Column)
    ).

play(Board, Moves, PlayerIndex) :-
    players(PlayerIndex, Player),
    ask_column(Board, Player, Column),
    ( Column == eof ->
        true
    ;
        lowest_empty_row(Board, Column, RowIndex),
        put(Board, RowIndex, Column, Player, NewBoard),
        NewMoves is Moves + 1,
        render(NewBoard, Text),
        nl,
        write(Text),
        nl,
        flush_output,
        ( has_four(NewBoard, Player) ->
            format("Player ~w wins!~n", [Player]),
            flush_output
        ; NewMoves =:= 42 ->
            format("It's a tie!~n", []),
            flush_output
        ;
            NextIndex is 1 - PlayerIndex,
            play(NewBoard, NewMoves, NextIndex)
        )
    ).

main :-
    empty_board(Board),
    render(Board, BoardText),
    header(HeaderText),
    write(HeaderText),
    nl,
    write(BoardText),
    nl,
    flush_output,
    play(Board, 0, 0).
