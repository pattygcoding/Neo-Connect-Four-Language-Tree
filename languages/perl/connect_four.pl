use strict;
use warnings;

$| = 1;

my $ROWS = 6;
my $COLS = 7;
my $EMPTY = ".";
my @PLAYERS = ("X", "O");
my $HEADER = "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n";

sub new_board {
    my @board;
    for (my $r = 0; $r < $ROWS; $r++) {
        my @row = ($EMPTY) x $COLS;
        push @board, \@row;
    }
    return \@board;
}

sub render {
    my ($board) = @_;
    my $labels = " " . join(" ", 1 .. $COLS);
    my $border = "+" . ("-" x ($COLS * 2 - 1)) . "+";
    my @lines = ($labels, $border);
    for (my $r = $ROWS - 1; $r >= 0; $r--) {
        push @lines, "|" . join(" ", @{ $board->[$r] }) . "|";
    }
    push @lines, $border;
    return join("\n", @lines);
}

sub lowest_empty_row {
    my ($board, $col) = @_;
    for (my $r = 0; $r < $ROWS; $r++) {
        return $r if $board->[$r][$col] eq $EMPTY;
    }
    return -1;
}

sub has_four {
    my ($board, $player) = @_;
    my $at = sub {
        my ($r, $c) = @_;
        return $board->[$r][$c] eq $player;
    };
    for (my $r = 0; $r < $ROWS; $r++) {
        for (my $c = 0; $c + 3 < $COLS; $c++) {
            return 1 if $at->($r, $c) && $at->($r, $c + 1) && $at->($r, $c + 2) && $at->($r, $c + 3);
        }
    }
    for (my $r = 0; $r + 3 < $ROWS; $r++) {
        for (my $c = 0; $c < $COLS; $c++) {
            return 1 if $at->($r, $c) && $at->($r + 1, $c) && $at->($r + 2, $c) && $at->($r + 3, $c);
        }
    }
    for (my $r = 0; $r + 3 < $ROWS; $r++) {
        for (my $c = 0; $c + 3 < $COLS; $c++) {
            return 1 if $at->($r, $c) && $at->($r + 1, $c + 1) && $at->($r + 2, $c + 2) && $at->($r + 3, $c + 3);
        }
    }
    for (my $r = 3; $r < $ROWS; $r++) {
        for (my $c = 0; $c + 3 < $COLS; $c++) {
            return 1 if $at->($r, $c) && $at->($r - 1, $c + 1) && $at->($r - 2, $c + 2) && $at->($r - 3, $c + 3);
        }
    }
    return 0;
}

sub whole_number {
    my ($token) = @_;
    return $token =~ /\A[+-]?[0-9]+\z/;
}

sub ask_column {
    my ($board, $player) = @_;
    while (1) {
        print "Player $player, choose a column (1-7): ";
        my $line = <STDIN>;
        if (!defined $line) {
            print "\nInput closed. Goodbye.\n";
            return undef;
        }
        my $token = $line;
        $token =~ s/^\s+//;
        $token =~ s/\s+$//;
        my $message;
        if ($token eq "") {
            $message = "Invalid input: no column entered.";
        } elsif (!whole_number($token)) {
            $message = "Invalid input: \"$token\" is not a whole number.";
        } else {
            my $value = $token + 0;
            if ($value < 1 || $value > $COLS) {
                $message = "Invalid input: \"$token\" is out of range (1-7).";
            } elsif (lowest_empty_row($board, $value - 1) == -1) {
                $message = "Column $value is full.";
            } else {
                return $value - 1;
            }
        }
        print "\n$message\n";
    }
}

sub main {
    my $board = new_board();
    print $HEADER . "\n" . render($board) . "\n";
    my $moves = 0;
    my $player_index = 0;
    while (1) {
        my $player = $PLAYERS[$player_index];
        my $column = ask_column($board, $player);
        return if !defined $column;
        my $row = lowest_empty_row($board, $column);
        $board->[$row][$column] = $player;
        $moves++;
        print "\n" . render($board) . "\n";
        if (has_four($board, $player)) {
            print "Player $player wins!\n";
            return;
        }
        if ($moves == $ROWS * $COLS) {
            print "It's a tie!\n";
            return;
        }
        $player_index = 1 - $player_index;
    }
}

main();
