let rows = 6
let cols = 7
let empty = '.'
let players = [| 'X'; 'O' |]

let header =
    "=== Connect Four ===\n"
    ^ "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

let new_board () = Array.init rows (fun _ -> Array.make cols empty)

let lowest_empty_row board column =
    let rec scan row =
        if row >= rows then -1
        else if board.(row).(column) = empty then row
        else scan (row + 1)
    in
    scan 0

let has_four board player =
    let inside row column =
        row >= 0 && row < rows && column >= 0 && column < cols
    in
    let at row column = inside row column && board.(row).(column) = player in
    let run row column drow dcolumn =
        at row column
        && at (row + drow) (column + dcolumn)
        && at (row + (2 * drow)) (column + (2 * dcolumn))
        && at (row + (3 * drow)) (column + (3 * dcolumn))
    in
    let found = ref false in
    for row = 0 to rows - 1 do
        for column = 0 to cols - 1 do
            if
                run row column 0 1 || run row column 1 0
                || run row column 1 1 || run row column 1 (-1)
            then found := true
        done
    done;
    !found

let print_border () =
    print_char '+';
    for _ = 1 to (cols * 2) - 1 do
        print_char '-'
    done;
    print_endline "+"

let print_board board =
    print_char ' ';
    for column = 1 to cols do
        if column > 1 then print_char ' ';
        print_char (Char.chr (Char.code '0' + column))
    done;
    print_newline ();
    print_border ();
    for row = rows - 1 downto 0 do
        print_char '|';
        for column = 0 to cols - 1 do
            if column > 0 then print_char ' ';
            print_char board.(row).(column)
        done;
        print_endline "|"
    done;
    print_border ()

let read_line_opt () = try Some (input_line stdin) with End_of_file -> None

let is_space character = character = ' ' || (character >= '\t' && character <= '\r')

let trim text =
    let length = String.length text in
    let start = ref 0 in
    while !start < length && is_space text.[!start] do
        incr start
    done;
    let stop = ref length in
    while !stop > !start && is_space text.[!stop - 1] do
        decr stop
    done;
    String.sub text !start (!stop - !start)

let is_whole_number token =
    let length = String.length token in
    let start = if length > 0 && (token.[0] = '+' || token.[0] = '-') then 1 else 0 in
    if start >= length then false
    else begin
        let whole = ref true in
        for index = start to length - 1 do
            if token.[index] < '0' || token.[index] > '9' then whole := false
        done;
        !whole
    end

let parse_value token =
    match int_of_string_opt token with
    | Some value -> value
    | None -> max_int

let ask_column board player =
    let rec prompt () =
        Printf.printf "Player %c, choose a column (1-7): " player;
        flush stdout;
        match read_line_opt () with
        | None ->
            print_string "\nInput closed. Goodbye.\n";
            flush stdout;
            -1
        | Some line ->
            let token = trim line in
            let outcome =
                if token = "" then Error "Invalid input: no column entered."
                else if not (is_whole_number token) then
                    Error (Printf.sprintf "Invalid input: \"%s\" is not a whole number." token)
                else
                    let value = parse_value token in
                    if value < 1 || value > cols then
                        Error (Printf.sprintf "Invalid input: \"%s\" is out of range (1-7)." token)
                    else if lowest_empty_row board (value - 1) < 0 then
                        Error (Printf.sprintf "Column %d is full." value)
                    else Ok (value - 1)
            in
            match outcome with
            | Ok column -> column
            | Error message ->
                print_string ("\n" ^ message ^ "\n");
                flush stdout;
                prompt ()
    in
    prompt ()

let () =
    let board = new_board () in
    print_string (header ^ "\n");
    print_board board;
    flush stdout;
    let moves = ref 0 in
    let player_index = ref 0 in
    let finished = ref false in
    while not !finished do
        let player = players.(!player_index) in
        let column = ask_column board player in
        if column < 0 then finished := true
        else begin
            let row = lowest_empty_row board column in
            board.(row).(column) <- player;
            incr moves;
            print_char '\n';
            print_board board;
            flush stdout;
            if has_four board player then begin
                Printf.printf "Player %c wins!\n" player;
                flush stdout;
                finished := true
            end
            else if !moves = rows * cols then begin
                print_string "It's a tie!\n";
                flush stdout;
                finished := true
            end
            else player_index := 1 - !player_index
        end
    done
