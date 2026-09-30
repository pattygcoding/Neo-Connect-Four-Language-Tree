-module(connect_four).
-export([main/0]).

-define(ROWS, 6).
-define(COLS, 7).
-define(EMPTY, $.).
-define(HEADER, "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n").

main() ->
    Board = new_board(),
    io:format("~s~n~s~n", [?HEADER, render(Board)]),
    loop(Board, 0, 0).

new_board() ->
    [[?EMPTY || _ <- lists:seq(1, ?COLS)] || _ <- lists:seq(1, ?ROWS)].

render(Board) ->
    Labels = " " ++ join([integer_to_list(C) || C <- lists:seq(1, ?COLS)], " "),
    Border = "+" ++ lists:duplicate(?COLS * 2 - 1, $-) ++ "+",
    RowStrings = ["|" ++ join([[C] || C <- Row], " ") ++ "|" || Row <- lists:reverse(Board)],
    lists:flatten([Labels, "\n", Border, "\n", join(RowStrings, "\n"), "\n", Border]).

join(Items, Separator) ->
    lists:flatten(lists:join(Separator, Items)).

at(Board, Row, Col) ->
    lists:nth(Col + 1, lists:nth(Row + 1, Board)).

lowest_empty_row(Board, Col) ->
    lowest_empty_row(Board, Col, 0).

lowest_empty_row([], _Col, _Row) ->
    -1;
lowest_empty_row([Cells | Rest], Col, Row) ->
    case lists:nth(Col + 1, Cells) of
        ?EMPTY -> Row;
        _ -> lowest_empty_row(Rest, Col, Row + 1)
    end.

put(Board, Row, Col, Value) ->
    Cells = lists:nth(Row + 1, Board),
    NewCells = lists:sublist(Cells, Col) ++ [Value] ++ lists:nthtail(Col + 1, Cells),
    lists:sublist(Board, Row) ++ [NewCells] ++ lists:nthtail(Row + 1, Board).

has_four(Board, Player) ->
    horizontal(Board, Player) orelse
        vertical(Board, Player) orelse
        diagonal_up(Board, Player) orelse
        diagonal_down(Board, Player).

horizontal(Board, Player) ->
    lists:any(
        fun(Row) ->
            lists:any(
                fun(Col) ->
                    at(Board, Row, Col) =:= Player andalso
                        at(Board, Row, Col + 1) =:= Player andalso
                        at(Board, Row, Col + 2) =:= Player andalso
                        at(Board, Row, Col + 3) =:= Player
                end,
                lists:seq(0, ?COLS - 4)
            )
        end,
        lists:seq(0, ?ROWS - 1)
    ).

vertical(Board, Player) ->
    lists:any(
        fun(Row) ->
            lists:any(
                fun(Col) ->
                    at(Board, Row, Col) =:= Player andalso
                        at(Board, Row + 1, Col) =:= Player andalso
                        at(Board, Row + 2, Col) =:= Player andalso
                        at(Board, Row + 3, Col) =:= Player
                end,
                lists:seq(0, ?COLS - 1)
            )
        end,
        lists:seq(0, ?ROWS - 4)
    ).

diagonal_up(Board, Player) ->
    lists:any(
        fun(Row) ->
            lists:any(
                fun(Col) ->
                    at(Board, Row, Col) =:= Player andalso
                        at(Board, Row + 1, Col + 1) =:= Player andalso
                        at(Board, Row + 2, Col + 2) =:= Player andalso
                        at(Board, Row + 3, Col + 3) =:= Player
                end,
                lists:seq(0, ?COLS - 4)
            )
        end,
        lists:seq(0, ?ROWS - 4)
    ).

diagonal_down(Board, Player) ->
    lists:any(
        fun(Row) ->
            lists:any(
                fun(Col) ->
                    at(Board, Row, Col) =:= Player andalso
                        at(Board, Row - 1, Col + 1) =:= Player andalso
                        at(Board, Row - 2, Col + 2) =:= Player andalso
                        at(Board, Row - 3, Col + 3) =:= Player
                end,
                lists:seq(0, ?COLS - 4)
            )
        end,
        lists:seq(3, ?ROWS - 1)
    ).

is_whole_number(Token) ->
    Body =
        case Token of
            [$+ | Rest] -> Rest;
            [$- | Rest] -> Rest;
            _ -> Token
        end,
    Body =/= [] andalso lists:all(fun(C) -> C >= $0 andalso C =< $9 end, Body).

to_integer(Token) ->
    {Sign, Digits} =
        case Token of
            [$+ | Rest] -> {1, Rest};
            [$- | Rest] -> {-1, Rest};
            _ -> {1, Token}
        end,
    Sign * list_to_integer(Digits).

validate(_Board, "") ->
    "Invalid input: no column entered.";
validate(Board, Token) ->
    case is_whole_number(Token) of
        false ->
            lists:flatten(
                io_lib:format("Invalid input: \"~s\" is not a whole number.", [Token])
            );
        true ->
            Value = to_integer(Token),
            if
                Value < 1; Value > ?COLS ->
                    lists:flatten(
                        io_lib:format("Invalid input: \"~s\" is out of range (1-7).", [Token])
                    );
                true ->
                    case lowest_empty_row(Board, Value - 1) of
                        -1 ->
                            lists:flatten(io_lib:format("Column ~b is full.", [Value]));
                        _ ->
                            ok
                    end
            end
    end.

ask_column(Board, Player) ->
    Prompt = lists:flatten(
        io_lib:format("Player ~c, choose a column (1-7): ", [Player])
    ),
    case io:get_line(Prompt) of
        eof ->
            io:format("~nInput closed. Goodbye.~n"),
            eof;
        Line ->
            Token = string:trim(Line),
            case validate(Board, Token) of
                ok ->
                    to_integer(Token) - 1;
                Message ->
                    io:format("~n~s~n", [Message]),
                    ask_column(Board, Player)
            end
    end.

loop(Board, Moves, PlayerIndex) ->
    Player = lists:nth(PlayerIndex + 1, [$X, $O]),
    case ask_column(Board, Player) of
        eof ->
            ok;
        Column ->
            Row = lowest_empty_row(Board, Column),
            NewBoard = put(Board, Row, Column, Player),
            NewMoves = Moves + 1,
            io:format("~n~s~n", [render(NewBoard)]),
            case has_four(NewBoard, Player) of
                true ->
                    io:format("Player ~c wins!~n", [Player]);
                false when NewMoves =:= ?ROWS * ?COLS ->
                    io:format("It's a tie!~n");
                false ->
                    loop(NewBoard, NewMoves, 1 - PlayerIndex)
            end
    end.
