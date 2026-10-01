class ConnectFourGame
    ROWS = 6
    COLUMNS = 7
    EMPTY = "."
    PLAYERS = %w[X O].freeze
    DIRECTIONS = [[0, 1], [1, 0], [1, 1], [1, -1]].freeze

    attr_reader :board, :moves

    def self.from_session(data)
        new.load(data)
    end

    def initialize
        @board = Array.new(ROWS) { Array.new(COLUMNS, EMPTY) }
        @moves = 0
    end

    def load(data)
        @board = data["board"]
        @moves = data["moves"]
        self
    end

    def to_session
        { "board" => @board, "moves" => @moves }
    end

    def current_player
        PLAYERS[@moves % PLAYERS.size]
    end

    def column_full?(column)
        lowest_empty_row(column).nil?
    end

    def drop(column)
        row = lowest_empty_row(column)
        return false if row.nil?

        @board[row][column] = current_player
        @moves += 1
        true
    end

    def winner
        PLAYERS.find { |player| winning_line?(player) }
    end

    def full?
        @moves == ROWS * COLUMNS
    end

    def finished?
        !winner.nil? || full?
    end

    private

    def lowest_empty_row(column)
        (0...ROWS).find { |row| @board[row][column] == EMPTY }
    end

    def winning_line?(player)
        ROWS.times do |row|
            COLUMNS.times do |column|
                next unless cell?(row, column, player)

                DIRECTIONS.each do |dr, dc|
                    return true if (1..3).all? { |step| cell?(row + dr * step, column + dc * step, player) }
                end
            end
        end
        false
    end

    def cell?(row, column, player)
        row.between?(0, ROWS - 1) && column.between?(0, COLUMNS - 1) && @board[row][column] == player
    end
end
