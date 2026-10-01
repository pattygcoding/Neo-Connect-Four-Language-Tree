class GamesController < ApplicationController
    def show
        @game = current_game
    end

    def create
        game = current_game
        column = params[:column].to_i - 1

        if playable?(game, column)
            game.drop(column)
        else
            flash.now[:alert] = "Column #{params[:column]} is not available."
        end

        session[:game] = game.to_session
        redirect_to root_path
    end

    def destroy
        session[:game] = ConnectFourGame.new.to_session
        redirect_to root_path
    end

    private

    def current_game
        ConnectFourGame.from_session(session[:game] || ConnectFourGame.new.to_session)
    end

    def playable?(game, column)
        column.between?(0, ConnectFourGame::COLUMNS - 1) && !game.column_full?(column)
    end
end
