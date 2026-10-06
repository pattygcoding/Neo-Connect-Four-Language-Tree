use serde::Serialize;

pub const ROWS: usize = 6;
pub const COLUMNS: usize = 7;
pub const EMPTY: &str = ".";
pub const PLAYERS: [&str; 2] = ["X", "O"];

const DIRECTIONS: [(isize, isize); 4] = [(0, 1), (1, 0), (1, 1), (1, -1)];

#[derive(Clone, Serialize)]
pub struct ConnectFourBoard {
    cells: Vec<Vec<String>>,
    moves: usize,
}

#[derive(Serialize)]
pub struct GameView {
    rows: Vec<Vec<String>>,
    status: String,
    over: bool,
    full: Vec<bool>,
}

impl Default for ConnectFourBoard {
    fn default() -> Self {
        Self::new()
    }
}

impl ConnectFourBoard {
    pub fn new() -> Self {
        Self {
            cells: vec![vec![EMPTY.to_string(); COLUMNS]; ROWS],
            moves: 0,
        }
    }

    fn current_player(&self) -> &str {
        PLAYERS[self.moves % PLAYERS.len()]
    }

    fn lowest_empty_row(&self, column: usize) -> Option<usize> {
        (0..ROWS).find(|&row| self.cells[row][column] == EMPTY)
    }

    pub fn is_full(&self, column: usize) -> bool {
        self.lowest_empty_row(column).is_none()
    }

    pub fn drop(&mut self, column: usize) -> bool {
        match self.lowest_empty_row(column) {
            Some(row) => {
                self.cells[row][column] = self.current_player().to_string();
                self.moves += 1;
                true
            }
            None => false,
        }
    }

    pub fn winner(&self) -> Option<&str> {
        PLAYERS.iter().copied().find(|&player| self.has_line(player))
    }

    pub fn is_over(&self) -> bool {
        self.winner().is_some() || self.moves == ROWS * COLUMNS
    }

    pub fn view(&self) -> GameView {
        let status = match self.winner() {
            Some(player) => format!("Player {player} wins!"),
            None if self.is_over() => "It's a tie!".to_string(),
            None => format!("Player {}, choose a column.", self.current_player()),
        };
        GameView {
            rows: self.cells.iter().rev().cloned().collect(),
            status,
            over: self.is_over(),
            full: (0..COLUMNS).map(|column| self.is_full(column)).collect(),
        }
    }

    fn has_line(&self, player: &str) -> bool {
        for row in 0..ROWS {
            for column in 0..COLUMNS {
                for (row_step, column_step) in DIRECTIONS {
                    if (1..4).all(|step| {
                        self.matches(
                            row as isize + row_step * step,
                            column as isize + column_step * step,
                            player,
                        )
                    }) {
                        return true;
                    }
                }
            }
        }
        false
    }

    fn matches(&self, row: isize, column: isize, player: &str) -> bool {
        row >= 0
            && row < ROWS as isize
            && column >= 0
            && column < COLUMNS as isize
            && self.cells[row as usize][column as usize] == player
    }
}
