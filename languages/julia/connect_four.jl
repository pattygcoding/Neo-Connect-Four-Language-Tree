const ROWS = 6
const COLS = 7
const EMPTY_CELL = '.'
const PLAYERS = ['X', 'O']
const HEADER = "=== Connect Four ==="
const RULES = "Get four of your pieces in a row to win. Columns are numbered 1-7."
const MAX_VALUE = typemax(Int64)

function new_board()
    return fill(EMPTY_CELL, ROWS, COLS)
end

function lowest_empty_row(board, column)
    for row in 1:ROWS
        if board[row, column] == EMPTY_CELL
            return row
        end
    end
    return -1
end

function run_matches(board, player, start_row, start_column, row_step, column_step)
    for step in 0:3
        row = start_row + step * row_step
        column = start_column + step * column_step
        if row < 1 || row > ROWS || column < 1 || column > COLS
            return false
        end
        if board[row, column] != player
            return false
        end
    end
    return true
end

function has_four(board, player)
    for row in 1:ROWS
        for column in 1:COLS
            if run_matches(board, player, row, column, 0, 1) ||
                run_matches(board, player, row, column, 1, 0) ||
                run_matches(board, player, row, column, 1, 1) ||
                run_matches(board, player, row, column, 1, -1)
                return true
            end
        end
    end
    return false
end

function border()
    return "+" * repeat("-", COLS * 2 - 1) * "+"
end

function render(board)
    lines = String[]
    push!(lines, " " * join(1:COLS, " "))
    push!(lines, border())
    for row in ROWS:-1:1
        push!(lines, "|" * join(board[row, :], " ") * "|")
    end
    push!(lines, border())
    return join(lines, "\n")
end

function is_whole_number(text)
    bytes = codeunits(text)
    index = 1
    if !isempty(bytes) && (bytes[1] == UInt8('+') || bytes[1] == UInt8('-'))
        index = 2
    end
    if index > length(bytes)
        return false
    end
    for position in index:length(bytes)
        byte = bytes[position]
        if byte < UInt8('0') || byte > UInt8('9')
            return false
        end
    end
    return true
end

function parse_value(text)
    bytes = codeunits(text)
    index = 1
    negative = false
    if !isempty(bytes) && (bytes[1] == UInt8('+') || bytes[1] == UInt8('-'))
        negative = bytes[1] == UInt8('-')
        index = 2
    end
    value = Int64(0)
    for position in index:length(bytes)
        digit = Int64(bytes[position]) - Int64(UInt8('0'))
        if value > div(MAX_VALUE - digit, 10)
            value = MAX_VALUE
            break
        end
        value = value * 10 + digit
    end
    if negative
        return -value
    end
    return value
end

function ask_column(board, player)
    while true
        print("Player $player, choose a column (1-7): ")
        flush(stdout)
        if eof(stdin)
            println("\nInput closed. Goodbye.")
            return -1
        end
        token = strip(readline())
        if isempty(token)
            println("\nInvalid input: no column entered.")
        elseif !is_whole_number(token)
            println("\nInvalid input: \"$token\" is not a whole number.")
        else
            value = parse_value(token)
            if value < 1 || value > COLS
                println("\nInvalid input: \"$token\" is out of range (1-7).")
            elseif lowest_empty_row(board, value) < 0
                println("\nColumn $value is full.")
            else
                return value
            end
        end
    end
end

function main()
    board = new_board()
    println(HEADER)
    println(RULES)
    println()
    println(render(board))
    player_index = 1
    moves = 0
    while true
        player = PLAYERS[player_index]
        column = ask_column(board, player)
        if column < 0
            break
        end
        row = lowest_empty_row(board, column)
        board[row, column] = player
        moves += 1
        println()
        println(render(board))
        if has_four(board, player)
            println("Player $player wins!")
            break
        end
        if moves == ROWS * COLS
            println("It's a tie!")
            break
        end
        player_index = 3 - player_index
    end
end

main()
