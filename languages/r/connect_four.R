rows <- 6
cols <- 7
empty_cell <- "."
players <- c("X", "O")
header <- "=== Connect Four ==="
rules <- "Get four of your pieces in a row to win. Columns are numbered 1-7."
input_stream <- file("stdin", "r")

trimmed <- function(text) {
    sub("^[[:space:]]+", "", sub("[[:space:]]+$", "", text))
}

new_board <- function() {
    matrix(empty_cell, nrow = rows, ncol = cols)
}

lowest_empty_row <- function(board, column) {
    for (row in 1:rows) {
        if (board[row, column] == empty_cell) {
            return(row)
        }
    }
    return(-1)
}

run_matches <- function(board, player, start_row, start_column, row_step, column_step) {
    for (step in 0:3) {
        row <- start_row + step * row_step
        column <- start_column + step * column_step
        if (row < 1 || row > rows || column < 1 || column > cols) {
            return(FALSE)
        }
        if (board[row, column] != player) {
            return(FALSE)
        }
    }
    return(TRUE)
}

has_four <- function(board, player) {
    for (row in 1:rows) {
        for (column in 1:cols) {
            if (run_matches(board, player, row, column, 0, 1) ||
                run_matches(board, player, row, column, 1, 0) ||
                run_matches(board, player, row, column, 1, 1) ||
                run_matches(board, player, row, column, 1, -1)) {
                return(TRUE)
            }
        }
    }
    return(FALSE)
}

border <- function() {
    paste0("+", strrep("-", cols * 2 - 1), "+")
}

render <- function(board) {
    lines <- character(0)
    lines <- c(lines, paste0(" ", paste(1:cols, collapse = " ")))
    lines <- c(lines, border())
    for (row in rows:1) {
        lines <- c(lines, paste0("|", paste(board[row, ], collapse = " "), "|"))
    }
    lines <- c(lines, border())
    return(paste(lines, collapse = "\n"))
}

is_whole_number <- function(text) {
    body <- text
    if (grepl("^[+-]", body)) {
        body <- substring(body, 2)
    }
    if (nchar(body) == 0) {
        return(FALSE)
    }
    return(grepl("^[0-9]+$", body))
}

parse_value <- function(text) {
    body <- text
    negative <- FALSE
    if (grepl("^[+-]", body)) {
        negative <- substr(body, 1, 1) == "-"
        body <- substring(body, 2)
    }
    limit <- 1e15
    value <- 0
    for (index in seq_len(nchar(body))) {
        digit <- as.numeric(substr(body, index, index))
        if (value > (limit - digit) / 10) {
            value <- limit
            break
        }
        value <- value * 10 + digit
    }
    if (negative) {
        return(-value)
    }
    return(value)
}

ask_column <- function(board, player) {
    repeat {
        cat(sprintf("Player %s, choose a column (1-7): ", player))
        flush(stdout())
        lines <- suppressWarnings(readLines(input_stream, n = 1))
        if (length(lines) == 0) {
            cat("\nInput closed. Goodbye.\n")
            return(-1)
        }
        token <- trimmed(lines[1])
        if (nchar(token) == 0) {
            cat("\nInvalid input: no column entered.\n")
        } else if (!is_whole_number(token)) {
            cat(sprintf("\nInvalid input: \"%s\" is not a whole number.\n", token))
        } else {
            value <- parse_value(token)
            if (value < 1 || value > cols) {
                cat(sprintf("\nInvalid input: \"%s\" is out of range (1-7).\n", token))
            } else if (lowest_empty_row(board, value) < 0) {
                cat(sprintf("\nColumn %d is full.\n", as.integer(value)))
            } else {
                return(value)
            }
        }
    }
}

main <- function() {
    board <- new_board()
    cat(sprintf("%s\n", header))
    cat(sprintf("%s\n", rules))
    cat("\n")
    cat(sprintf("%s\n", render(board)))
    player_index <- 1
    moves <- 0
    repeat {
        player <- players[player_index]
        column <- ask_column(board, player)
        if (column < 0) {
            break
        }
        row <- lowest_empty_row(board, column)
        board[row, column] <- player
        moves <- moves + 1
        cat("\n")
        cat(sprintf("%s\n", render(board)))
        if (has_four(board, player)) {
            cat(sprintf("Player %s wins!\n", player))
            break
        }
        if (moves == rows * cols) {
            cat("It's a tie!\n")
            break
        }
        player_index <- 3 - player_index
    }
}

main()
