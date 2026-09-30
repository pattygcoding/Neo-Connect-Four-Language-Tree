local ROWS = 6
local COLS = 7
local EMPTY = "."
local PLAYERS = { "X", "O" }

local label_parts = {}
for c = 1, COLS do
    label_parts[#label_parts + 1] = tostring(c)
end
local LABELS = " " .. table.concat(label_parts, " ")
local BORDER = "+" .. string.rep("-", COLS * 2 - 1) .. "+"
local HEADER = "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n"

local function new_board()
    local board = {}
    for r = 1, ROWS do
        board[r] = {}
        for c = 1, COLS do
            board[r][c] = EMPTY
        end
    end
    return board
end

local function render(board)
    local out = { LABELS, BORDER }
    for r = ROWS, 1, -1 do
        local cells = {}
        for c = 1, COLS do
            cells[c] = board[r][c]
        end
        out[#out + 1] = "|" .. table.concat(cells, " ") .. "|"
    end
    out[#out + 1] = BORDER
    return table.concat(out, "\n")
end

local function lowest_empty_row(board, col)
    for r = 1, ROWS do
        if board[r][col] == EMPTY then
            return r
        end
    end
    return -1
end

local function has_four(board, p)
    for r = 1, ROWS do
        for c = 1, COLS - 3 do
            if board[r][c] == p and board[r][c + 1] == p and board[r][c + 2] == p and board[r][c + 3] == p then
                return true
            end
        end
    end
    for r = 1, ROWS - 3 do
        for c = 1, COLS do
            if board[r][c] == p and board[r + 1][c] == p and board[r + 2][c] == p and board[r + 3][c] == p then
                return true
            end
        end
    end
    for r = 1, ROWS - 3 do
        for c = 1, COLS - 3 do
            if board[r][c] == p and board[r + 1][c + 1] == p and board[r + 2][c + 2] == p and board[r + 3][c + 3] == p then
                return true
            end
        end
    end
    for r = 4, ROWS do
        for c = 1, COLS - 3 do
            if board[r][c] == p and board[r - 1][c + 1] == p and board[r - 2][c + 2] == p and board[r - 3][c + 3] == p then
                return true
            end
        end
    end
    return false
end

local function is_whole_number(token)
    local body = token
    if token:sub(1, 1) == "+" or token:sub(1, 1) == "-" then
        body = token:sub(2)
    end
    return body:match("^%d+$") ~= nil
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ask_column(board, player)
    while true do
        io.write("Player " .. player .. ", choose a column (1-7): ")
        io.flush()
        local raw = io.read("*l")
        if raw == nil then
            io.write("\nInput closed. Goodbye.\n")
            return nil
        end
        local token = trim(raw)
        local message
        if token == "" then
            message = "Invalid input: no column entered."
        elseif not is_whole_number(token) then
            message = 'Invalid input: "' .. token .. '" is not a whole number.'
        else
            local numstr = token
            if numstr:sub(1, 1) == "+" then
                numstr = numstr:sub(2)
            end
            local value = tonumber(numstr)
            if value == nil or value < 1 or value > COLS then
                message = 'Invalid input: "' .. token .. '" is out of range (1-7).'
            elseif lowest_empty_row(board, value) == -1 then
                message = "Column " .. string.format("%d", value) .. " is full."
            else
                return value
            end
        end
        io.write("\n" .. message .. "\n")
    end
end

local function main()
    local board = new_board()
    io.write(HEADER .. "\n" .. render(board) .. "\n")
    local moves = 0
    local player_index = 1
    while true do
        local player = PLAYERS[player_index]
        local column = ask_column(board, player)
        if column == nil then
            return
        end
        board[lowest_empty_row(board, column)][column] = player
        moves = moves + 1
        io.write("\n" .. render(board) .. "\n")
        if has_four(board, player) then
            io.write("Player " .. player .. " wins!\n")
            return
        end
        if moves == ROWS * COLS then
            io.write("It's a tie!\n")
            return
        end
        player_index = 3 - player_index
    end
end

main()
