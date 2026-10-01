defmodule ConnectFourWeb.Router do
  use ConnectFourWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ConnectFourWeb do
    pipe_through :browser

    get "/", GameController, :board
    post "/move", GameController, :move
    delete "/reset", GameController, :reset
  end
end
