#include <cctype>
#include <iostream>
#include <string>

namespace {

constexpr int ROWS = 6;
constexpr int COLS = 7;
constexpr char EMPTY = '.';
const char PLAYERS[2] = {'X', 'O'};
const std::string HEADER =
    "=== Connect Four ===\n"
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

std::string border() {
    std::string b = "+";
    b.append(COLS * 2 - 1, '-');
    b += "+";
    return b;
}

std::string labels() {
    std::string b = " ";
    for (int c = 1; c <= COLS; ++c) {
        if (c > 1) {
            b += ' ';
        }
        b += static_cast<char>('0' + c);
    }
    return b;
}

std::string render(char board[ROWS][COLS]) {
    std::string out = labels() + "\n" + border() + "\n";
    for (int r = ROWS - 1; r >= 0; --r) {
        out += '|';
        for (int c = 0; c < COLS; ++c) {
            if (c > 0) {
                out += ' ';
            }
            out += board[r][c];
        }
        out += "|\n";
    }
    out += border();
    return out;
}

int lowestEmptyRow(char board[ROWS][COLS], int col) {
    for (int r = 0; r < ROWS; ++r) {
        if (board[r][col] == EMPTY) {
            return r;
        }
    }
    return -1;
}

bool hasFour(char board[ROWS][COLS], char p) {
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c + 3 < COLS; ++c) {
            if (board[r][c] == p && board[r][c + 1] == p
                && board[r][c + 2] == p && board[r][c + 3] == p) {
                return true;
            }
        }
    }
    for (int r = 0; r + 3 < ROWS; ++r) {
        for (int c = 0; c < COLS; ++c) {
            if (board[r][c] == p && board[r + 1][c] == p
                && board[r + 2][c] == p && board[r + 3][c] == p) {
                return true;
            }
        }
    }
    for (int r = 0; r + 3 < ROWS; ++r) {
        for (int c = 0; c + 3 < COLS; ++c) {
            if (board[r][c] == p && board[r + 1][c + 1] == p
                && board[r + 2][c + 2] == p && board[r + 3][c + 3] == p) {
                return true;
            }
        }
    }
    for (int r = 3; r < ROWS; ++r) {
        for (int c = 0; c + 3 < COLS; ++c) {
            if (board[r][c] == p && board[r - 1][c + 1] == p
                && board[r - 2][c + 2] == p && board[r - 3][c + 3] == p) {
                return true;
            }
        }
    }
    return false;
}

bool isWholeNumber(const std::string& token) {
    std::size_t i = 0;
    if (!token.empty() && (token[0] == '+' || token[0] == '-')) {
        i = 1;
    }
    if (i >= token.size()) {
        return false;
    }
    for (std::size_t k = i; k < token.size(); ++k) {
        if (token[k] < '0' || token[k] > '9') {
            return false;
        }
    }
    return true;
}

std::string trim(const std::string& s) {
    std::size_t a = 0;
    std::size_t b = s.size();
    while (a < b && std::isspace(static_cast<unsigned char>(s[a]))) {
        ++a;
    }
    while (b > a && std::isspace(static_cast<unsigned char>(s[b - 1]))) {
        --b;
    }
    return s.substr(a, b - a);
}

int askColumn(char board[ROWS][COLS], char player) {
    for (;;) {
        std::cout << "Player " << player << ", choose a column (1-7): ";
        std::cout.flush();
        std::string line;
        if (!std::getline(std::cin, line)) {
            std::cout << "\nInput closed. Goodbye.\n";
            return -1;
        }
        const std::string token = trim(line);
        std::string message;
        if (token.empty()) {
            message = "Invalid input: no column entered.";
        } else if (!isWholeNumber(token)) {
            message = "Invalid input: \"" + token + "\" is not a whole number.";
        } else {
            long long value = 0;
            bool ok = true;
            try {
                value = std::stoll(token);
            } catch (...) {
                ok = false;
            }
            if (!ok || value < 1 || value > COLS) {
                message = "Invalid input: \"" + token + "\" is out of range (1-7).";
            } else if (lowestEmptyRow(board, static_cast<int>(value) - 1) < 0) {
                message = "Column " + std::to_string(value) + " is full.";
            } else {
                return static_cast<int>(value) - 1;
            }
        }
        std::cout << "\n" << message << "\n";
    }
}

}  // namespace

int main() {
    char board[ROWS][COLS];
    for (int r = 0; r < ROWS; ++r) {
        for (int c = 0; c < COLS; ++c) {
            board[r][c] = EMPTY;
        }
    }
    std::cout << HEADER << "\n" << render(board) << "\n";

    int moves = 0;
    int playerIndex = 0;
    for (;;) {
        const char player = PLAYERS[playerIndex];
        const int column = askColumn(board, player);
        if (column < 0) {
            return 0;
        }
        board[lowestEmptyRow(board, column)][column] = player;
        ++moves;
        std::cout << "\n" << render(board) << "\n";
        if (hasFour(board, player)) {
            std::cout << "Player " << player << " wins!\n";
            return 0;
        }
        if (moves == ROWS * COLS) {
            std::cout << "It's a tie!\n";
            return 0;
        }
        playerIndex = 1 - playerIndex;
    }
}

