defmodule ConnectFourWeb.GameController do
  use ConnectFourWeb, :controller

  alias ConnectFour.Game

  def board(conn, _params) do
    game = current_game(conn)
    render(conn, :board, game: game, status: Game.status(game), columns: 1..Game.columns())
  end

  def move(conn, %{"column" => column}) do
    game = current_game(conn)
    value = String.to_integer(column)

    game =
      if value >= 1 and value <= Game.columns() and not Game.over?(game) and
           not Game.full?(game, value - 1) do
        Game.drop(game, value - 1)
      else
        game
      end

    conn
    |> put_session(:board, Game.to_session(game))
    |> redirect(to: ~p"/")
  end

  def reset(conn, _params) do
    conn
    |> delete_session(:board)
    |> redirect(to: ~p"/")
  end

  defp current_game(conn) do
    conn
    |> get_session(:board)
    |> Game.from_session()
  end
end
