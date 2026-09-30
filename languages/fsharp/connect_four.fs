module ConnectFour

open System
open System.Text

let rows = 6
let cols = 7
let empty = '.'
let players = [| 'X'; 'O' |]
let border = "+" + String('-', cols * 2 - 1) + "+"
let labels = " " + String.concat " " [ for c in 1 .. cols -> string c ]
let header =
    "=== Connect Four ===\n" +
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

let newBoard () : char[][] =
    Array.init rows (fun _ -> Array.create cols empty)

let render (board: char[][]) =
    let sb = StringBuilder()
    sb.Append(labels).Append('\n') |> ignore
    sb.Append(border).Append('\n') |> ignore
    for r in (rows - 1) .. -1 .. 0 do
        sb.Append('|') |> ignore
        for c in 0 .. (cols - 1) do
            if c > 0 then
                sb.Append(' ') |> ignore
            sb.Append(board.[r].[c]) |> ignore
        sb.Append("|\n") |> ignore
    sb.Append(border) |> ignore
    sb.ToString()

let lowestEmptyRow (board: char[][]) (col: int) =
    let mutable row = -1
    let mutable r = 0
    while row < 0 && r < rows do
        if board.[r].[col] = empty then
            row <- r
        r <- r + 1
    row

let hasFour (board: char[][]) (player: char) =
    let at r c = board.[r].[c] = player
    let mutable found = false
    for r in 0 .. (rows - 1) do
        for c in 0 .. (cols - 4) do
            if at r c && at r (c + 1) && at r (c + 2) && at r (c + 3) then
                found <- true
    for r in 0 .. (rows - 4) do
        for c in 0 .. (cols - 1) do
            if at r c && at (r + 1) c && at (r + 2) c && at (r + 3) c then
                found <- true
    for r in 0 .. (rows - 4) do
        for c in 0 .. (cols - 4) do
            if at r c && at (r + 1) (c + 1) && at (r + 2) (c + 2) && at (r + 3) (c + 3) then
                found <- true
    for r in 3 .. (rows - 1) do
        for c in 0 .. (cols - 4) do
            if at r c && at (r - 1) (c + 1) && at (r - 2) (c + 2) && at (r - 3) (c + 3) then
                found <- true
    found

let isWholeNumber (token: string) =
    let body =
        if token.StartsWith("+") || token.StartsWith("-") then token.Substring(1)
        else token
    body.Length > 0 && (body |> Seq.forall (fun ch -> ch >= '0' && ch <= '9'))

let askColumn (board: char[][]) (player: char) =
    let rec loop () =
        Console.Out.Write("Player " + string player + ", choose a column (1-7): ")
        Console.Out.Flush()
        let raw = Console.In.ReadLine()
        if isNull raw then
            Console.Out.Write("\nInput closed. Goodbye.\n")
            Console.Out.Flush()
            -1
        else
            let token = raw.Trim()
            let mutable message = ""
            let mutable column = -1
            if token.Length = 0 then
                message <- "Invalid input: no column entered."
            elif not (isWholeNumber token) then
                message <- "Invalid input: \"" + token + "\" is not a whole number."
            else
                let mutable value = 0L
                if not (Int64.TryParse(token, &value)) then
                    value <- Int64.MaxValue
                if value < 1L || value > int64 cols then
                    message <- "Invalid input: \"" + token + "\" is out of range (1-7)."
                elif lowestEmptyRow board (int value - 1) < 0 then
                    message <- "Column " + string value + " is full."
                else
                    column <- int value - 1
            if column >= 0 then
                column
            else
                Console.Out.Write("\n" + message + "\n")
                Console.Out.Flush()
                loop ()
    loop ()

[<EntryPoint>]
let main _ =
    let board = newBoard ()
    Console.Out.Write(header + "\n" + render board + "\n")
    Console.Out.Flush()
    let mutable moves = 0
    let mutable playerIndex = 0
    let mutable finished = false
    while not finished do
        let player = players.[playerIndex]
        let column = askColumn board player
        if column < 0 then
            finished <- true
        else
            board.[lowestEmptyRow board column].[column] <- player
            moves <- moves + 1
            Console.Out.Write("\n" + render board + "\n")
            if hasFour board player then
                Console.Out.Write("Player " + string player + " wins!\n")
                Console.Out.Flush()
                finished <- true
            elif moves = rows * cols then
                Console.Out.Write("It's a tie!\n")
                Console.Out.Flush()
                finished <- true
            else
                playerIndex <- 1 - playerIndex
    0
