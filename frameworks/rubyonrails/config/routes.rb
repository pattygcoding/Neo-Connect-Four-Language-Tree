Rails.application.routes.draw do
    root "games#show"

    post "move", to: "games#create", as: :move
    delete "reset", to: "games#destroy", as: :reset
end
