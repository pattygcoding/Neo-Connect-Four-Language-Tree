defmodule ConnectFour.Game do
  @rows 6
  @columns 7
  @empty "."
  @players ["X", "O"]
  @directions [{0, 1}, {1, 0}, {1, 1}, {1, -1}]

  defstruct cells: nil, moves: 0

  def new do
    cells = for _ <- 1..@rows, do: List.duplicate(@empty, @columns)
    %__MODULE__{cells: cells, moves: 0}
  end

  def from_session(nil), do: new()

  def from_session(%{"cells" => cells, "moves" => moves}) do
    %__MODULE__{cells: cells, moves: moves}
  end

  def from_session(_other), do: new()

  def to_session(%__MODULE__{cells: cells, moves: moves}) do
    %{"cells" => cells, "moves" => moves}
  end

  def columns, do: @columns

  def current_player(%__MODULE__{moves: moves}) do
    Enum.at(@players, rem(moves, length(@players)))
  end

  def winner(%__MODULE__{cells: cells}) do
    Enum.find(@players, fn player -> has_line?(cells, player) end)
  end

  def over?(%__MODULE__{} = game) do
    winner(game) != nil or game.moves == @rows * @columns
  end

  def full?(%__MODULE__{cells: cells}, column) do
    lowest_empty_row(cells, column) == nil
  end

  def drop(%__MODULE__{} = game, column) do
    case lowest_empty_row(game.cells, column) do
      nil ->
        game

      row ->
        cells =
          List.update_at(game.cells, row, fn row_cells ->
            List.replace_at(row_cells, column, current_player(game))
          end)

        %__MODULE__{game | cells: cells, moves: game.moves + 1}
    end
  end

  def status(%__MODULE__{} = game) do
    cond do
      winner(game) -> "Player #{winner(game)} wins!"
      over?(game) -> "It's a tie!"
      true -> "Player #{current_player(game)}, choose a column."
    end
  end

  defp lowest_empty_row(cells, column) do
    Enum.find(0..(@rows - 1), fn row ->
      Enum.at(Enum.at(cells, row), column) == @empty
    end)
  end

  defp has_line?(cells, player) do
    Enum.any?(0..(@rows - 1), fn row ->
      Enum.any?(0..(@columns - 1), fn column ->
        cell?(cells, row, column, player) and
          Enum.any?(@directions, fn {row_step, column_step} ->
            Enum.all?(1..3, fn step ->
              cell?(cells, row + row_step * step, column + column_step * step, player)
            end)
          end)
      end)
    end)
  end

  defp cell?(cells, row, column, player) do
    row in 0..(@rows - 1) and column in 0..(@columns - 1) and
      Enum.at(Enum.at(cells, row), column) == player
  end
end
