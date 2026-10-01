#include <objc/message.h>
#include <objc/objc.h>
#include <objc/runtime.h>
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

__attribute__((objc_root_class))
@interface CFObject
{
    Class isa;
}
+ (id)alloc;
- (void)dealloc;
@end

@implementation CFObject
+ (id)alloc {
    return class_createInstance(self, 0);
}

- (void)dealloc {
    object_dispose(self);
}
@end

@interface Board : CFObject
{
    char cells[ROWS][COLS];
}
- (id)init;
- (char)cellAtRow:(int)row column:(int)column;
- (void)setCellAtRow:(int)row column:(int)column to:(char)value;
- (int)lowestEmptyRowInColumn:(int)column;
- (int)hasFourForPlayer:(char)player;
- (void)printBorder;
- (void)print;
@end

@implementation Board
- (id)init {
    int row;
    int column;
    for (row = 0; row < ROWS; ++row) {
        for (column = 0; column < COLS; ++column) {
            cells[row][column] = EMPTY;
        }
    }
    return self;
}

- (char)cellAtRow:(int)row column:(int)column {
    return cells[row][column];
}

- (void)setCellAtRow:(int)row column:(int)column to:(char)value {
    cells[row][column] = value;
}

- (int)lowestEmptyRowInColumn:(int)column {
    int row;
    for (row = 0; row < ROWS; ++row) {
        if (cells[row][column] == EMPTY) {
            return row;
        }
    }
    return -1;
}

- (int)hasFourForPlayer:(char)player {
    int row;
    int column;
    int k;
    for (row = 0; row < ROWS; ++row) {
        for (column = 0; column + 3 < COLS; ++column) {
            for (k = 0; k < 4 && cells[row][column + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    for (row = 0; row + 3 < ROWS; ++row) {
        for (column = 0; column < COLS; ++column) {
            for (k = 0; k < 4 && cells[row + k][column] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    for (row = 0; row + 3 < ROWS; ++row) {
        for (column = 0; column + 3 < COLS; ++column) {
            for (k = 0; k < 4 && cells[row + k][column + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    for (row = 3; row < ROWS; ++row) {
        for (column = 0; column + 3 < COLS; ++column) {
            for (k = 0; k < 4 && cells[row - k][column + k] == player; ++k) {
            }
            if (k == 4) {
                return 1;
            }
        }
    }
    return 0;
}

- (void)printBorder {
    int index;
    putchar('+');
    for (index = 0; index < COLS * 2 - 1; ++index) {
        putchar('-');
    }
    puts("+");
}

- (void)print {
    int row;
    int column;
    putchar(' ');
    for (column = 1; column <= COLS; ++column) {
        if (column > 1) {
            putchar(' ');
        }
        putchar((char)('0' + column));
    }
    putchar('\n');
    [self printBorder];
    for (row = ROWS - 1; row >= 0; --row) {
        putchar('|');
        for (column = 0; column < COLS; ++column) {
            if (column > 0) {
                putchar(' ');
            }
            putchar(cells[row][column]);
        }
        puts("|");
    }
    [self printBorder];
}
@end

static int isSpaceChar(unsigned char character) {
    return character == ' ' || (character >= 9 && character <= 13);
}

static char *readLine(void) {
    size_t capacity = 128;
    size_t length = 0;
    char *line = malloc(capacity);
    int character;
    int got = 0;
    if (line == NULL) {
        return NULL;
    }
    while ((character = getchar()) != EOF) {
        got = 1;
        if (character == '\n') {
            break;
        }
        if (length + 1 >= capacity) {
            char *grown = realloc(line, capacity * 2);
            if (grown == NULL) {
                free(line);
                return NULL;
            }
            line = grown;
            capacity *= 2;
        }
        line[length++] = (char)character;
    }
    if (!got) {
        free(line);
        return NULL;
    }
    line[length] = '\0';
    return line;
}

static char *strip(char *text) {
    char *end;
    while (*text != '\0' && isSpaceChar((unsigned char)*text)) {
        ++text;
    }
    end = text + strlen(text);
    while (end > text && isSpaceChar((unsigned char)end[-1])) {
        --end;
    }
    *end = '\0';
    return text;
}

static int isWholeNumber(const char *text) {
    if (*text == '+' || *text == '-') {
        ++text;
    }
    if (*text == '\0') {
        return 0;
    }
    for (; *text != '\0'; ++text) {
        if (*text < '0' || *text > '9') {
            return 0;
        }
    }
    return 1;
}

@interface Game : CFObject
{
    Board *board;
    int moves;
    int playerIndex;
}
- (id)init;
- (void)dealloc;
- (int)askColumnForPlayer:(char)player;
- (void)run;
@end

@implementation Game
- (id)init {
    board = [[Board alloc] init];
    moves = 0;
    playerIndex = 0;
    return self;
}

- (void)dealloc {
    [board dealloc];
    [super dealloc];
}

- (int)askColumnForPlayer:(char)player {
    for (;;) {
        char *line;
        char *token;
        char message[256];
        printf("Player %c, choose a column (1-7): ", player);
        fflush(stdout);
        line = readLine();
        if (line == NULL) {
            printf("\nInput closed. Goodbye.\n");
            fflush(stdout);
            return -1;
        }
        token = strip(line);
        if (*token == '\0') {
            snprintf(message, sizeof(message),
                "Invalid input: no column entered.");
        } else if (!isWholeNumber(token)) {
            snprintf(message, sizeof(message),
                "Invalid input: \"%s\" is not a whole number.", token);
        } else {
            long value = strtol(token, NULL, 10);
            if (value < 1 || value > COLS) {
                snprintf(message, sizeof(message),
                    "Invalid input: \"%s\" is out of range (1-7).", token);
            } else if ([board lowestEmptyRowInColumn:(int)value - 1] < 0) {
                snprintf(message, sizeof(message), "Column %ld is full.", value);
            } else {
                int column = (int)value - 1;
                free(line);
                return column;
            }
        }
        printf("\n%s\n", message);
        fflush(stdout);
        free(line);
    }
}

- (void)run {
    printf("%s\n", HEADER);
    [board print];
    for (;;) {
        char player = PLAYERS[playerIndex];
        int column = [self askColumnForPlayer:player];
        int row;
        if (column < 0) {
            return;
        }
        row = [board lowestEmptyRowInColumn:column];
        [board setCellAtRow:row column:column to:player];
        ++moves;
        putchar('\n');
        [board print];
        if ([board hasFourForPlayer:player]) {
            printf("Player %c wins!\n", player);
            return;
        }
        if (moves == ROWS * COLS) {
            printf("It's a tie!\n");
            return;
        }
        playerIndex = 1 - playerIndex;
    }
}
@end

int main(void) {
    Game *game = [[Game alloc] init];
    [game run];
    [game dealloc];
    return 0;
}
