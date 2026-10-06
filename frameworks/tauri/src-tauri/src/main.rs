#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod board;

use std::sync::Mutex;

use board::{ConnectFourBoard, COLUMNS};
use tauri::State;

struct GameState(Mutex<ConnectFourBoard>);

#[tauri::command]
fn new_game(state: State<GameState>) -> board::GameView {
    let mut game = state.0.lock().expect("lock game");
    *game = ConnectFourBoard::new();
    game.view()
}

#[tauri::command]
fn play(column: usize, state: State<GameState>) -> board::GameView {
    let mut game = state.0.lock().expect("lock game");
    if !game.is_over() && column < COLUMNS && !game.is_full(column) {
        game.drop(column);
    }
    game.view()
}

fn main() {
    tauri::Builder::default()
        .manage(GameState(Mutex::new(ConnectFourBoard::new())))
        .invoke_handler(tauri::generate_handler![new_game, play])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
