mod board;

use std::sync::Arc;

use axum::{
    extract::{Form, State},
    response::{Html, IntoResponse, Redirect},
    routing::{get, post},
    Router,
};
use board::{ConnectFourBoard, COLUMNS};
use minijinja::{context, Environment};
use serde::Deserialize;
use tower_sessions::{MemoryStore, Session, SessionManagerLayer};

struct AppState {
    templates: Environment<'static>,
}

#[tokio::main]
async fn main() {
    let mut templates = Environment::new();
    templates
        .add_template("board.html", include_str!("../templates/board.html"))
        .expect("board.html template");

    let session_layer = SessionManagerLayer::new(MemoryStore::default());

    let app = Router::new()
        .route("/", get(board_page))
        .route("/move", post(move_handler))
        .route("/reset", post(reset))
        .layer(session_layer)
        .with_state(Arc::new(AppState { templates }));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .expect("bind listener");
    axum::serve(listener, app).await.expect("serve");
}

async fn current_board(session: &Session) -> ConnectFourBoard {
    session
        .get::<ConnectFourBoard>("board")
        .await
        .ok()
        .flatten()
        .unwrap_or_default()
}

async fn board_page(State(state): State<Arc<AppState>>, session: Session) -> impl IntoResponse {
    let game = current_board(&session).await;
    let columns: Vec<usize> = (1..=COLUMNS).collect();
    let rendered = state
        .templates
        .get_template("board.html")
        .expect("template registered")
        .render(context! {
            board => game,
            rows => game.rows_top_down(),
            columns,
            winner => game.winner(),
            over => game.is_over(),
        })
        .expect("render board");
    Html(rendered)
}

#[derive(Deserialize)]
struct MoveForm {
    column: usize,
}

async fn move_handler(
    session: Session,
    State(_state): State<Arc<AppState>>,
    Form(form): Form<MoveForm>,
) -> impl IntoResponse {
    let mut game = current_board(&session).await;
    if !game.is_over()
        && form.column >= 1
        && form.column <= COLUMNS
        && !game.is_full(form.column - 1)
    {
        game.drop(form.column - 1);
    }
    let _ = session.insert("board", game).await;
    Redirect::to("/")
}

async fn reset(session: Session, State(_state): State<Arc<AppState>>) -> impl IntoResponse {
    let _ = session.insert("board", ConnectFourBoard::new()).await;
    Redirect::to("/")
}
