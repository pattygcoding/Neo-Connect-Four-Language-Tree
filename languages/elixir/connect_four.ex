defmodule ConnectFour do
    @rows 6
    @cols 7
    @empty "."
    @players ["X", "O"]
    @header "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n"

    def main do
        board = new_board()
        IO.write(@header <> "\n" <> render(board) <> "\n")
        loop(board, 0, 0)
    end

    defp new_board do
        for _ <- 1..@rows, do: List.duplicate(@empty, @cols)
    end

    defp render(board) do
        labels = " " <> Enum.join(1..@cols, " ")
        border = "+" <> String.duplicate("-", @cols * 2 - 1) <> "+"

        rows =
            board
            |> Enum.reverse()
            |> Enum.map(fn row -> "|" <> Enum.join(row, " ") <> "|" end)
            |> Enum.join("\n")

        labels <> "\n" <> border <> "\n" <> rows <> "\n" <> border
    end

    defp at(board, row, col) do
        board |> Enum.at(row) |> Enum.at(col)
    end

    defp lowest_empty_row(board, col) do
        board
        |> Enum.with_index()
        |> Enum.find(fn {cells, _index} -> Enum.at(cells, col) == @empty end)
        |> case do
            {_cells, index} -> index
            nil -> -1
        end
    end

    defp put(board, row, col, value) do
        List.update_at(board, row, fn cells -> List.replace_at(cells, col, value) end)
    end

    defp has_four(board, player) do
        horizontal =
            Enum.any?(0..(@rows - 1), fn row ->
                Enum.any?(0..(@cols - 4), fn col ->
                    at(board, row, col) == player and at(board, row, col + 1) == player and
                        at(board, row, col + 2) == player and at(board, row, col + 3) == player
                end)
            end)

        vertical =
            Enum.any?(0..(@rows - 4), fn row ->
                Enum.any?(0..(@cols - 1), fn col ->
                    at(board, row, col) == player and at(board, row + 1, col) == player and
                        at(board, row + 2, col) == player and at(board, row + 3, col) == player
                end)
            end)

        diagonal_up =
            Enum.any?(0..(@rows - 4), fn row ->
                Enum.any?(0..(@cols - 4), fn col ->
                    at(board, row, col) == player and at(board, row + 1, col + 1) == player and
                        at(board, row + 2, col + 2) == player and at(board, row + 3, col + 3) == player
                end)
            end)

        diagonal_down =
            Enum.any?(3..(@rows - 1), fn row ->
                Enum.any?(0..(@cols - 4), fn col ->
                    at(board, row, col) == player and at(board, row - 1, col + 1) == player and
                        at(board, row - 2, col + 2) == player and at(board, row - 3, col + 3) == player
                end)
            end)

        horizontal or vertical or diagonal_up or diagonal_down
    end

    defp whole_number?(token) do
        body =
            case token do
                "+" <> rest -> rest
                "-" <> rest -> rest
                _ -> token
            end

        body != "" and String.match?(body, ~r/\A[0-9]+\z/)
    end

    defp validate(_board, "") do
        {:error, "Invalid input: no column entered."}
    end

    defp validate(board, token) do
        if whole_number?(token) do
            {value, ""} = Integer.parse(token)

            cond do
                value < 1 or value > @cols ->
                    {:error, "Invalid input: \"#{token}\" is out of range (1-7)."}

                lowest_empty_row(board, value - 1) == -1 ->
                    {:error, "Column #{value} is full."}

                true ->
                    {:ok, value - 1}
            end
        else
            {:error, "Invalid input: \"#{token}\" is not a whole number."}
        end
    end

    defp ask_column(board, player) do
        case IO.gets("Player #{player}, choose a column (1-7): ") do
            :eof ->
                IO.write("\nInput closed. Goodbye.\n")
                nil

            line ->
                case validate(board, String.trim(line)) do
                    {:ok, column} ->
                        column

                    {:error, message} ->
                        IO.write("\n" <> message <> "\n")
                        ask_column(board, player)
                end
        end
    end

    defp loop(board, moves, player_index) do
        player = Enum.at(@players, player_index)

        case ask_column(board, player) do
            nil ->
                :ok

            column ->
                row = lowest_empty_row(board, column)
                board = put(board, row, column, player)
                moves = moves + 1
                IO.write("\n" <> render(board) <> "\n")

                cond do
                    has_four(board, player) ->
                        IO.write("Player #{player} wins!\n")

                    moves == @rows * @cols ->
                        IO.write("It's a tie!\n")

                    true ->
                        loop(board, moves, 1 - player_index)
                end
        end
    end
end

ConnectFour.main()
