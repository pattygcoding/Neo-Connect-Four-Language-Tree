#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ROWS 6
#define COLS 7
#define EMPTY '.'

static const char *PLAYERS = "XO";

static const char *HEADER =
    "=== Connect Four ===\n"
    "Get four of your pieces in a row to win. Columns are numbered 1-7.\n";

/* Print the column labels line. */
static void print_labels(void) {
    int col;
    putchar(' ');
    for (col = 1; col <= COLS; ++col) {
        if (col > 1) {
            putchar(' ');
        }
        putchar((char)('0' + col));
    }
    putchar('\n');
}

static void print_border(void) {
    int i;
    putchar('+');
    for (i = 0; i < COLS * 2 - 1; ++i) {
        putchar('-');
    }
    puts("+");
}

static void print_board(char board[ROWS][COLS]) {
    int row;
    print_labels();
    print_border();
    for (row = ROWS - 1; row >= 0; --row) {
        int col;
        putchar('|');
        for (col = 0; col < COLS; ++col) {
            if (col > 0) {
                putchar(' ');
            }
            putchar(board[row][col]);
        }
        puts("|");
    }
    print_border();
}

/* Return the lowest empty row in `col`, or -1 if the column is full. */
static int lowest_empty_row(char board[ROWS][COLS], int col) {
    int row;
    for (row = 0; row < ROWS; ++row) {
        if (board[row][col] == EMPTY) {
            return row;
        }
    }
    return -1;
}

/* Return 1 if `player` has four in a row anywhere on the board. */
static int has_four(char board[ROWS][COLS], char player) {
    int row, col, k;
    /* Horizontal. */
    for (row = 0; row < ROWS; ++row) {
        for (col = 0; col + 3 < COLS; ++col) {
            for (k = 0; k < 4 && board[row][col + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    /* Vertical. */
    for (row = 0; row + 3 < ROWS; ++row) {
        for (col = 0; col < COLS; ++col) {
            for (k = 0; k < 4 && board[row + k][col] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    /* Diagonal (up-right). */
    for (row = 0; row + 3 < ROWS; ++row) {
        for (col = 0; col + 3 < COLS; ++col) {
            for (k = 0; k < 4 && board[row + k][col + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    /* Diagonal (down-right). */
    for (row = 3; row < ROWS; ++row) {
        for (col = 0; col + 3 < COLS; ++col) {
            for (k = 0; k < 4 && board[row - k][col + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    return 0;
}

/* True only for an optional sign followed by ASCII digits. */
static int is_whole_number(const char *s) {
    if (*s == '+' || *s == '-') {
        ++s;
    }
    if (*s == '\0') {
        return 0;
    }
    for (; *s != '\0'; ++s) {
        if (*s < '0' || *s > '9') {
            return 0;
        }
    }
    return 1;
}

// Read one line from stdin without the trailing newline.  Returns a
// malloc'd string (caller frees) or NULL at end of input.
static char *read_line(void) {
    size_t cap = 128;
    size_t len = 0;
    char *line = malloc(cap);
    int c;
    int got = 0;
    if (line == NULL) {
        return NULL;
    }
    while ((c = getchar()) != EOF) {
        got = 1;
        if (c == '\n') {
            break;
        }
        if (len + 1 >= cap) {
            char *grown = realloc(line, cap * 2);
            if (grown == NULL) {
                free(line);
                return NULL;
            }
            line = grown;
            cap *= 2;
        }
        line[len++] = (char)c;
    }
    if (!got) {
        free(line);
        return NULL;
    }
    line[len] = '\0';
    return line;
}

/* Strip leading/trailing whitespace in place and return the new start. */
static char *strip(char *s) {
    char *end;
    while (*s != '\0' && isspace((unsigned char)*s)) {
        ++s;
    }
    end = s + strlen(s);
    while (end > s && isspace((unsigned char)end[-1])) {
        --end;
    }
    *end = '\0';
    return s;
}

// Read a valid zero-based column from stdin, or return -1 when the input
// stream is closed.
static int ask_column(char board[ROWS][COLS], char player) {
    for (;;) {
        char *line;
        char *token;
        char message[256];
        printf("Player %c, choose a column (1-7): ", player);
        fflush(stdout);
        line = read_line();
        if (line == NULL) {
            printf("\nInput closed. Goodbye.\n");
            return -1;
        }
        token = strip(line);
        if (*token == '\0') {
            snprintf(message, sizeof(message),
                    "Invalid input: no column entered.");
        } else if (!is_whole_number(token)) {
            snprintf(message, sizeof(message),
                    "Invalid input: \"%s\" is not a whole number.", token);
        } else {
            long value = strtol(token, NULL, 10);
            if (value < 1 || value > COLS) {
                snprintf(message, sizeof(message),
                        "Invalid input: \"%s\" is out of range (1-7).", token);
            } else if (lowest_empty_row(board, (int)value - 1) < 0) {
                snprintf(message, sizeof(message), "Column %ld is full.", value);
            } else {
                int col = (int)value - 1;
                free(line);
                return col;
            }
        }
        printf("\n%s\n", message);
        fflush(stdout);
        free(line);
    }
}

int main(void) {
    char board[ROWS][COLS];
    int moves = 0;
    int player_index = 0;
    int row, col;

    for (row = 0; row < ROWS; ++row) {
        for (col = 0; col < COLS; ++col) {
            board[row][col] = EMPTY;
        }
    }

    printf("%s\n", HEADER);
    print_board(board);

    for (;;) {
        char player = PLAYERS[player_index];
        int column = ask_column(board, player);
        if (column < 0) {
            return 0;
        }
        row = lowest_empty_row(board, column);
        board[row][column] = player;
        ++moves;
        putchar('\n');
        print_board(board);
        if (has_four(board, player)) {
            printf("Player %c wins!\n", player);
            return 0;
        }
        if (moves == ROWS * COLS) {
            printf("It's a tie!\n");
            return 0;
        }
        player_index = 1 - player_index;
    }
}
