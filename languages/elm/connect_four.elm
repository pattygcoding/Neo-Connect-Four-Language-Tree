port module ConnectFour exposing (main)

import Platform


port toHost : String -> Cmd msg


port fromHost : (Maybe String -> msg) -> Sub msg


port quitToHost : String -> Cmd msg


type Player
    = PlayerX
    | PlayerO


type alias Model =
    { board : List (List Char)
    , player : Player
    , moves : Int
    , finished : Bool
    }


type Msg
    = Received (Maybe String)


rows : Int
rows =
    6


cols : Int
cols =
    7


emptyCell : Char
emptyCell =
    '.'


maxValue : Int
maxValue =
    2147483647


spaceChars : List Char
spaceChars =
    [ ' ', '\t', '\n', '\u{000B}', '\u{000C}', '\r' ]


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( initialModel, toHost (intro ++ renderBoard initialModel.board ++ prompt initialModel.player) )
        , update = update
        , subscriptions = \_ -> fromHost Received
        }


initialModel : Model
initialModel =
    { board = List.repeat rows (List.repeat cols emptyCell)
    , player = PlayerX
    , moves = 0
    , finished = False
    }


intro : String
intro =
    "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n\n"


playerName : Player -> String
playerName player =
    case player of
        PlayerX ->
            "X"

        PlayerO ->
            "O"


prompt : Player -> String
prompt player =
    "Player " ++ playerName player ++ ", choose a column (1-7): "


renderBoard : List (List Char) -> String
renderBoard board =
    let
        labelLine =
            " " ++ String.join " " (List.map String.fromInt (List.range 1 cols))

        ruleLine =
            "+" ++ String.repeat (cols * 2 - 1) "-" ++ "+"

        rowLine row =
            "|" ++ String.fromList (List.intersperse ' ' row) ++ "|"
    in
    String.join "\n" (labelLine :: ruleLine :: List.map rowLine (List.reverse board) ++ [ ruleLine ]) ++ "\n"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Received Nothing ->
            if model.finished then
                ( model, Cmd.none )

            else
                ( { model | finished = True }
                , Cmd.batch [ toHost "\nInput closed. Goodbye.\n", quitToHost "done" ]
                )

        Received (Just line) ->
            if model.finished then
                ( model, Cmd.none )

            else
                handleLine (trim line) model


handleLine : String -> Model -> ( Model, Cmd Msg )
handleLine token model =
    if String.isEmpty token then
        reject "Invalid input: no column entered." model

    else if not (isWholeNumber token) then
        reject ("Invalid input: \"" ++ token ++ "\" is not a whole number.") model

    else if parseValue token < 1 || parseValue token > cols then
        reject ("Invalid input: \"" ++ token ++ "\" is out of range (1-7).") model

    else
        place (parseValue token - 1) model


reject : String -> Model -> ( Model, Cmd Msg )
reject message model =
    ( model, toHost ("\n" ++ message ++ "\n" ++ prompt model.player) )


place : Int -> Model -> ( Model, Cmd Msg )
place column model =
    case lowestEmptyRow column model.board of
        Nothing ->
            ( model, toHost ("\nColumn " ++ String.fromInt (column + 1) ++ " is full.\n" ++ prompt model.player) )

        Just row ->
            let
                stone =
                    playerChar model.player

                board =
                    setCell row column stone model.board

                moves =
                    model.moves + 1

                nextPlayer =
                    other model.player
            in
            if hasFour stone board then
                ( { model | board = board, moves = moves, finished = True }
                , Cmd.batch
                    [ toHost ("\n" ++ renderBoard board ++ "Player " ++ playerName model.player ++ " wins!\n")
                    , quitToHost "done"
                    ]
                )

            else if moves == rows * cols then
                ( { model | board = board, moves = moves, finished = True }
                , Cmd.batch
                    [ toHost ("\n" ++ renderBoard board ++ "It's a tie!\n")
                    , quitToHost "done"
                    ]
                )

            else
                ( { model | board = board, moves = moves, player = nextPlayer }
                , toHost ("\n" ++ renderBoard board ++ prompt nextPlayer)
                )


playerChar : Player -> Char
playerChar player =
    case player of
        PlayerX ->
            'X'

        PlayerO ->
            'O'


other : Player -> Player
other player =
    case player of
        PlayerX ->
            PlayerO

        PlayerO ->
            PlayerX


lowestEmptyRow : Int -> List (List Char) -> Maybe Int
lowestEmptyRow column board =
    List.range 0 (rows - 1)
        |> List.filter (\row -> getCell row column board == emptyCell)
        |> List.head


getCell : Int -> Int -> List (List Char) -> Char
getCell row column board =
    board
        |> List.drop row
        |> List.head
        |> Maybe.withDefault []
        |> List.drop column
        |> List.head
        |> Maybe.withDefault emptyCell


setCell : Int -> Int -> Char -> List (List Char) -> List (List Char)
setCell row column value board =
    List.indexedMap
        (\index currentRow ->
            if index == row then
                List.indexedMap
                    (\columnIndex cell ->
                        if columnIndex == column then
                            value

                        else
                            cell
                    )
                    currentRow

            else
                currentRow
        )
        board


hasFour : Char -> List (List Char) -> Bool
hasFour player board =
    List.any
        (\row ->
            List.any
                (\column ->
                    runMatches row column 0 1 player board
                        || runMatches row column 1 0 player board
                        || runMatches row column 1 1 player board
                        || runMatches row column 1 -1 player board
                )
                (List.range 0 (cols - 1))
        )
        (List.range 0 (rows - 1))


runMatches : Int -> Int -> Int -> Int -> Char -> List (List Char) -> Bool
runMatches row column rowStep columnStep player board =
    List.all
        (\step ->
            let
                targetRow =
                    row + step * rowStep

                targetColumn =
                    column + step * columnStep
            in
            targetRow >= 0
                && targetRow < rows
                && targetColumn >= 0
                && targetColumn < cols
                && getCell targetRow targetColumn board
                == player
        )
        (List.range 0 3)


trim : String -> String
trim text =
    let
        dropLeading chars =
            case chars of
                first :: rest ->
                    if List.member first spaceChars then
                        dropLeading rest

                    else
                        chars

                [] ->
                    []
    in
    String.fromList (List.reverse (dropLeading (List.reverse (dropLeading (String.toList text)))))


isWholeNumber : String -> Bool
isWholeNumber text =
    let
        body =
            bodyOf text
    in
    not (String.isEmpty body) && String.all (\c -> c >= '0' && c <= '9') body


bodyOf : String -> String
bodyOf text =
    case String.uncons text of
        Just ( first, rest ) ->
            if first == '+' || first == '-' then
                rest

            else
                text

        Nothing ->
            text


parseValue : String -> Int
parseValue text =
    if String.startsWith "-" text then
        negate (digits (bodyOf text))

    else
        digits (bodyOf text)


digits : String -> Int
digits body =
    String.foldl
        (\c value ->
            let
                digit =
                    Char.toCode c - Char.toCode '0'
            in
            if value > (maxValue - digit) // 10 then
                maxValue

            else
                value * 10 + digit
        )
        0
        body
