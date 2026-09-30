ROWS = 6
COLS = 7
EMPTY = "."
PLAYERS = %w[X O].freeze
BORDER = "+" + ("-" * (COLS * 2 - 1)) + "+"
LABELS = " " + (1..COLS).map(&:to_s).join(" ")
HEADER = "=== Connect Four ===\n" \
                "Get four of your pieces in a row to win. Columns are numbered 1-7.\n"

def new_board
    Array.new(ROWS) { Array.new(COLS, EMPTY) }
end

def render(board)
    lines = [LABELS, BORDER]
    (ROWS - 1).downto(0) { |r| lines << "|" + board[r].join(" ") + "|" }
    lines << BORDER
    lines.join("\n")
end

def lowest_empty_row(board, col)
    (0...ROWS).each { |r| return r if board[r][col] == EMPTY }
    -1
end

def has_four(board, p)
    (0...ROWS).each do |r|
        (0...(COLS - 3)).each do |c|
            return true if board[r][c] == p && board[r][c + 1] == p &&
                                        board[r][c + 2] == p && board[r][c + 3] == p
        end
    end
    (0...(ROWS - 3)).each do |r|
        (0...COLS).each do |c|
            return true if board[r][c] == p && board[r + 1][c] == p &&
                                        board[r + 2][c] == p && board[r + 3][c] == p
        end
    end
    (0...(ROWS - 3)).each do |r|
        (0...(COLS - 3)).each do |c|
            return true if board[r][c] == p && board[r + 1][c + 1] == p &&
                                        board[r + 2][c + 2] == p && board[r + 3][c + 3] == p
        end
    end
    (3...ROWS).each do |r|
        (0...(COLS - 3)).each do |c|
            return true if board[r][c] == p && board[r - 1][c + 1] == p &&
                                        board[r - 2][c + 2] == p && board[r - 3][c + 3] == p
        end
    end
    false
end

def whole_number?(token)
    body = token.start_with?("+", "-") ? token[1..] : token
    !body.empty? && body.match?(/\A[0-9]+\z/)
end

def ask_column(board, player)
    loop do
        $stdout.write("Player #{player}, choose a column (1-7): ")
        $stdout.flush
        raw = $stdin.gets
        if raw.nil?
            $stdout.write("\nInput closed. Goodbye.\n")
            return nil
        end
        token = raw.strip
        message =
            if token.empty?
                "Invalid input: no column entered."
            elsif !whole_number?(token)
                "Invalid input: \"#{token}\" is not a whole number."
            else
                value = token.to_i
                if value < 1 || value > COLS
                    "Invalid input: \"#{token}\" is out of range (1-7)."
                elsif lowest_empty_row(board, value - 1) == -1
                    "Column #{value} is full."
                else
                    return value - 1
                end
            end
        $stdout.write("\n" + message + "\n")
    end
end

def main
    board = new_board
    $stdout.write(HEADER + "\n" + render(board) + "\n")
    moves = 0
    player_index = 0
    loop do
        player = PLAYERS[player_index]
        column = ask_column(board, player)
        return if column.nil?

        board[lowest_empty_row(board, column)][column] = player
        moves += 1
        $stdout.write("\n" + render(board) + "\n")
        if has_four(board, player)
            $stdout.write("Player #{player} wins!\n")
            return
        end
        if moves == ROWS * COLS
            $stdout.write("It's a tie!\n")
            return
        end
        player_index = 1 - player_index
    end
end

main
