use std::io::{self, Write};

const ROWS: usize = 6;
const COLS: usize = 7;
const EMPTY: char = '.';
const PLAYERS: [char; 2] = ['X', 'O'];
const HEADER: &str = "=== Connect Four ===\n\
Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

fn border() -> String {
    format!("+{}+", "-".repeat(COLS * 2 - 1))
}

fn labels() -> String {
    let mut out = String::from(" ");
    for c in 1..=COLS {
        if c > 1 {
            out.push(' ');
        }
        out.push((b'0' + c as u8) as char);
    }
    out
}

fn render(board: &[[char; COLS]; ROWS]) -> String {
    let mut out = String::new();
    out.push_str(&labels());
    out.push('\n');
    out.push_str(&border());
    out.push('\n');
    for r in (0..ROWS).rev() {
        out.push('|');
        for c in 0..COLS {
            if c > 0 {
                out.push(' ');
            }
            out.push(board[r][c]);
        }
        out.push_str("|\n");
    }
    out.push_str(&border());
    out
}

fn lowest_empty_row(board: &[[char; COLS]; ROWS], col: usize) -> i32 {
    for r in 0..ROWS {
        if board[r][col] == EMPTY {
            return r as i32;
        }
    }
    -1
}

fn has_four(board: &[[char; COLS]; ROWS], p: char) -> bool {
    let at = |r: usize, c: usize| board[r][c] == p;
    for r in 0..ROWS {
        for c in 0..COLS - 3 {
            if at(r, c) && at(r, c + 1) && at(r, c + 2) && at(r, c + 3) {
                return true;
            }
        }
    }
    for r in 0..ROWS - 3 {
        for c in 0..COLS {
            if at(r, c) && at(r + 1, c) && at(r + 2, c) && at(r + 3, c) {
                return true;
            }
        }
    }
    for r in 0..ROWS - 3 {
        for c in 0..COLS - 3 {
            if at(r, c) && at(r + 1, c + 1) && at(r + 2, c + 2) && at(r + 3, c + 3) {
                return true;
            }
        }
    }
    for r in 3..ROWS {
        for c in 0..COLS - 3 {
            if at(r, c) && at(r - 1, c + 1) && at(r - 2, c + 2) && at(r - 3, c + 3) {
                return true;
            }
        }
    }
    false
}

fn is_whole_number(token: &str) -> bool {
    let body = if token.starts_with('+') || token.starts_with('-') {
        &token[1..]
    } else {
        token
    };
    !body.is_empty() && body.bytes().all(|b| b.is_ascii_digit())
}

fn read_line() -> Option<String> {
    let mut line = String::new();
    match io::stdin().read_line(&mut line) {
        Ok(0) => None,
        Ok(_) => Some(line),
        Err(_) => None,
    }
}

fn ask_column(board: &mut [[char; COLS]; ROWS], player: char) -> Option<usize> {
    loop {
        print!("Player {}, choose a column (1-7): ", player);
        let _ = io::stdout().flush();
        let raw = match read_line() {
            Some(line) => line,
            None => {
                print!("\nInput closed. Goodbye.\n");
                return None;
            }
        };
        let token = raw.trim();
        let message: String;
        if token.is_empty() {
            message = "Invalid input: no column entered.".to_string();
        } else if !is_whole_number(token) {
            message = format!("Invalid input: \"{}\" is not a whole number.", token);
        } else {
            match token.parse::<i64>() {
                Ok(value) if value >= 1 && value <= COLS as i64 => {
                    let col = (value - 1) as usize;
                    if lowest_empty_row(board, col) < 0 {
                        message = format!("Column {} is full.", value);
                    } else {
                        return Some(col);
                    }
                }
                _ => {
                    message = format!("Invalid input: \"{}\" is out of range (1-7).", token);
                }
            }
        }
        print!("\n{}\n", message);
        let _ = io::stdout().flush();
    }
}

fn main() {
    let mut board = [[EMPTY; COLS]; ROWS];
    print!("{}\n{}\n", HEADER, render(&board));
    let _ = io::stdout().flush();

    let mut moves = 0;
    let mut player_index = 0usize;
    loop {
        let player = PLAYERS[player_index];
        match ask_column(&mut board, player) {
            None => return,
            Some(column) => {
                let row = lowest_empty_row(&board, column) as usize;
                board[row][column] = player;
                moves += 1;
                print!("\n{}\n", render(&board));
                if has_four(&board, player) {
                    print!("Player {} wins!\n", player);
                    return;
                }
                if moves == ROWS * COLS {
                    print!("It's a tie!\n");
                    return;
                }
                player_index = 1 - player_index;
            }
        }
    }
}
