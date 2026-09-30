IDENTIFICATION DIVISION.
PROGRAM-ID. connect-four.

ENVIRONMENT DIVISION.

DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-BOARD.
    05 WS-ROW OCCURS 6 TIMES.
        10 WS-CELL PIC X OCCURS 7 TIMES.
01 WS-LABELS PIC X(14) VALUE " 1 2 3 4 5 6 7".
01 WS-BORDER PIC X(15) VALUE "+-------------+".
01 WS-TEXT PIC X(20).
01 WS-LINE PIC X(80).
01 WS-TOKEN PIC X(80).
01 WS-LEN PIC 9(4).
01 WS-TRIM-LEN PIC 9(4).
01 WS-START PIC 9(4).
01 WS-FINISH PIC 9(4).
01 WS-I PIC 9(4).
01 WS-J PIC 9(4).
01 WS-SIGLEN PIC 9(4).
01 WS-POS PIC 9(4).
01 WS-R PIC 9(4).
01 WS-C PIC 9(4).
01 WS-COL PIC 9(4).
01 WS-ROWIDX PIC 9(4).
01 WS-MOVES PIC 9(4) VALUE 0.
01 WS-PLAYER-IDX PIC 9(4) VALUE 0.
01 WS-DIGSTART PIC 9(4).
01 WS-ERR PIC 9.
01 WS-CODE PIC S9(9) COMP-5.
01 WS-VALUE PIC S9(9) COMP-5.
01 WS-PLAYER PIC X.
01 WS-DONE PIC X VALUE "N".
01 WS-VALID PIC X.
01 WS-EOL PIC X.
01 WS-AT-EOF PIC X.
01 WS-OK PIC X.
01 WS-FOUND PIC X.
01 WS-WON PIC X.

PROCEDURE DIVISION.
MAIN-PARA.
    PERFORM INIT-BOARD
    DISPLAY "=== Connect Four ==="
    DISPLAY "Get four of your pieces in a row to win. Columns are numbered 1-7."
    DISPLAY SPACE
    PERFORM SHOW-BOARD
    PERFORM FLUSH-OUT
    MOVE 0 TO WS-MOVES
    MOVE 0 TO WS-PLAYER-IDX
    PERFORM PLAY-LOOP UNTIL WS-DONE = "Y"
    STOP RUN.

INIT-BOARD.
    PERFORM VARYING WS-R FROM 1 BY 1 UNTIL WS-R > 6
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 7
            MOVE "." TO WS-CELL(WS-R, WS-C)
        END-PERFORM
    END-PERFORM.

SHOW-BOARD.
    DISPLAY WS-LABELS
    DISPLAY WS-BORDER
    PERFORM VARYING WS-R FROM 6 BY -1 UNTIL WS-R < 1
        MOVE SPACES TO WS-TEXT
        MOVE "|" TO WS-TEXT(1:1)
        MOVE "|" TO WS-TEXT(15:1)
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 7
            COMPUTE WS-POS = WS-C * 2
            MOVE WS-CELL(WS-R, WS-C) TO WS-TEXT(WS-POS:1)
        END-PERFORM
        DISPLAY WS-TEXT(1:15)
    END-PERFORM
    DISPLAY WS-BORDER.

LOWEST-EMPTY-ROW.
    MOVE "N" TO WS-FOUND
    MOVE 0 TO WS-ROWIDX
    MOVE 1 TO WS-R
    PERFORM UNTIL WS-R > 6 OR WS-FOUND = "Y"
        IF WS-CELL(WS-R, WS-COL) = "."
            MOVE "Y" TO WS-FOUND
            MOVE WS-R TO WS-ROWIDX
        ELSE
            ADD 1 TO WS-R
        END-IF
    END-PERFORM.

DROP-PIECE.
    PERFORM LOWEST-EMPTY-ROW
    MOVE WS-PLAYER TO WS-CELL(WS-ROWIDX, WS-COL).

FLUSH-OUT.
    CALL STATIC "fflush" USING BY VALUE 0.

READ-LINE.
    MOVE SPACES TO WS-LINE
    MOVE 0 TO WS-LEN
    MOVE "N" TO WS-EOL
    MOVE "N" TO WS-AT-EOF
    PERFORM UNTIL WS-EOL = "Y"
        CALL STATIC "getchar" RETURNING WS-CODE
        IF WS-CODE = -1
            MOVE "Y" TO WS-EOL
            IF WS-LEN = 0
                MOVE "Y" TO WS-AT-EOF
            END-IF
        ELSE
            IF WS-CODE = 13
                CONTINUE
            ELSE
                IF WS-CODE = 10
                    MOVE "Y" TO WS-EOL
                ELSE
                    IF WS-LEN < 80
                        ADD 1 TO WS-LEN
                        MOVE FUNCTION CHAR(WS-CODE + 1) TO WS-LINE(WS-LEN:1)
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

TRIM-LINE.
    MOVE 1 TO WS-START
    MOVE WS-LEN TO WS-FINISH
    PERFORM UNTIL WS-START > WS-FINISH
        IF WS-LINE(WS-START:1) = SPACE OR WS-LINE(WS-START:1) = X"09"
            ADD 1 TO WS-START
        ELSE
            EXIT PERFORM
        END-IF
    END-PERFORM
    PERFORM UNTIL WS-FINISH < WS-START
        IF WS-LINE(WS-FINISH:1) = SPACE OR WS-LINE(WS-FINISH:1) = X"09"
            SUBTRACT 1 FROM WS-FINISH
        ELSE
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF WS-FINISH < WS-START
        MOVE 0 TO WS-TRIM-LEN
        MOVE SPACES TO WS-TOKEN
    ELSE
        COMPUTE WS-TRIM-LEN = WS-FINISH - WS-START + 1
        MOVE SPACES TO WS-TOKEN
        MOVE WS-LINE(WS-START:WS-TRIM-LEN) TO WS-TOKEN(1:WS-TRIM-LEN)
    END-IF.

DIGITS-VALUE.
    MOVE WS-DIGSTART TO WS-J
    PERFORM UNTIL WS-J > WS-TRIM-LEN
        IF WS-TOKEN(WS-J:1) = "0"
            ADD 1 TO WS-J
        ELSE
            EXIT PERFORM
        END-IF
    END-PERFORM
    COMPUTE WS-SIGLEN = WS-TRIM-LEN - WS-J + 1
    IF WS-SIGLEN = 0
        MOVE 0 TO WS-VALUE
    ELSE
        IF WS-SIGLEN > 2
            MOVE 999 TO WS-VALUE
        ELSE
            COMPUTE WS-VALUE = FUNCTION NUMVAL(WS-TOKEN(WS-J:WS-SIGLEN))
        END-IF
    END-IF.

VALIDATE-TOKEN.
    MOVE "N" TO WS-OK
    MOVE 0 TO WS-ERR
    MOVE 0 TO WS-VALUE
    IF WS-TRIM-LEN = 0
        MOVE 1 TO WS-ERR
    ELSE
        IF WS-TOKEN(1:1) = "+" OR WS-TOKEN(1:1) = "-"
            MOVE 2 TO WS-DIGSTART
        ELSE
            MOVE 1 TO WS-DIGSTART
        END-IF
        MOVE "Y" TO WS-OK
        MOVE WS-DIGSTART TO WS-I
        PERFORM UNTIL WS-I > WS-TRIM-LEN OR WS-OK = "N"
            IF WS-TOKEN(WS-I:1) >= "0" AND WS-TOKEN(WS-I:1) <= "9"
                ADD 1 TO WS-I
            ELSE
                MOVE "N" TO WS-OK
                MOVE 2 TO WS-ERR
            END-IF
        END-PERFORM
        IF WS-OK = "Y" AND WS-DIGSTART > WS-TRIM-LEN
            MOVE "N" TO WS-OK
            MOVE 2 TO WS-ERR
        END-IF
        IF WS-OK = "Y" AND WS-TOKEN(1:1) = "-"
            MOVE "N" TO WS-OK
            MOVE 3 TO WS-ERR
        END-IF
        IF WS-OK = "Y"
            PERFORM DIGITS-VALUE
            IF WS-VALUE < 1 OR WS-VALUE > 7
                MOVE "N" TO WS-OK
                MOVE 3 TO WS-ERR
            ELSE
                MOVE WS-VALUE TO WS-COL
                PERFORM LOWEST-EMPTY-ROW
                IF WS-FOUND = "N"
                    MOVE "N" TO WS-OK
                    MOVE 4 TO WS-ERR
                END-IF
            END-IF
        END-IF
    END-IF.

SHOW-ERROR.
    DISPLAY SPACE
    EVALUATE WS-ERR
        WHEN 1
            DISPLAY "Invalid input: no column entered."
        WHEN 2
            DISPLAY "Invalid input: """ WS-TOKEN(1:WS-TRIM-LEN) """ is not a whole number."
        WHEN 3
            DISPLAY "Invalid input: """ WS-TOKEN(1:WS-TRIM-LEN) """ is out of range (1-7)."
        WHEN OTHER
            PERFORM SHOW-FULL
    END-EVALUATE.

SHOW-FULL.
    EVALUATE WS-COL
        WHEN 1 DISPLAY "Column 1 is full."
        WHEN 2 DISPLAY "Column 2 is full."
        WHEN 3 DISPLAY "Column 3 is full."
        WHEN 4 DISPLAY "Column 4 is full."
        WHEN 5 DISPLAY "Column 5 is full."
        WHEN 6 DISPLAY "Column 6 is full."
        WHEN 7 DISPLAY "Column 7 is full."
    END-EVALUATE.

ASK-COLUMN.
    DISPLAY "Player " WS-PLAYER ", choose a column (1-7): " WITH NO ADVANCING
    PERFORM FLUSH-OUT
    PERFORM READ-LINE
    IF WS-AT-EOF = "Y"
        DISPLAY SPACE
        DISPLAY "Input closed. Goodbye."
        PERFORM FLUSH-OUT
    ELSE
        PERFORM TRIM-LINE
        PERFORM VALIDATE-TOKEN
        IF WS-OK = "Y"
            MOVE "Y" TO WS-VALID
        ELSE
            PERFORM SHOW-ERROR
            PERFORM FLUSH-OUT
        END-IF
    END-IF.

PLAY-LOOP.
    IF WS-PLAYER-IDX = 0
        MOVE "X" TO WS-PLAYER
    ELSE
        MOVE "O" TO WS-PLAYER
    END-IF
    MOVE "N" TO WS-VALID
    MOVE "N" TO WS-AT-EOF
    PERFORM ASK-COLUMN UNTIL WS-VALID = "Y" OR WS-AT-EOF = "Y"
    IF WS-AT-EOF = "Y"
        MOVE "Y" TO WS-DONE
    ELSE
        PERFORM DROP-PIECE
        ADD 1 TO WS-MOVES
        DISPLAY SPACE
        PERFORM SHOW-BOARD
        PERFORM FLUSH-OUT
        PERFORM CHECK-WIN
        IF WS-DONE = "N"
            IF WS-MOVES = 42
                DISPLAY "It's a tie!"
                PERFORM FLUSH-OUT
                MOVE "Y" TO WS-DONE
            ELSE
                COMPUTE WS-PLAYER-IDX = 1 - WS-PLAYER-IDX
            END-IF
        END-IF
    END-IF.

CHECK-WIN.
    MOVE "N" TO WS-WON
    PERFORM CHECK-HORIZONTAL
    IF WS-WON = "N"
        PERFORM CHECK-VERTICAL
    END-IF
    IF WS-WON = "N"
        PERFORM CHECK-DIAGONAL-UP
    END-IF
    IF WS-WON = "N"
        PERFORM CHECK-DIAGONAL-DOWN
    END-IF
    IF WS-WON = "Y"
        DISPLAY "Player " WS-PLAYER " wins!"
        PERFORM FLUSH-OUT
        MOVE "Y" TO WS-DONE
    END-IF.

CHECK-HORIZONTAL.
    PERFORM VARYING WS-R FROM 1 BY 1 UNTIL WS-R > 6 OR WS-WON = "Y"
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 4 OR WS-WON = "Y"
            IF WS-CELL(WS-R, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R, WS-C + 1) = WS-PLAYER
                AND WS-CELL(WS-R, WS-C + 2) = WS-PLAYER
                AND WS-CELL(WS-R, WS-C + 3) = WS-PLAYER
                MOVE "Y" TO WS-WON
            END-IF
        END-PERFORM
    END-PERFORM.

CHECK-VERTICAL.
    PERFORM VARYING WS-R FROM 1 BY 1 UNTIL WS-R > 3 OR WS-WON = "Y"
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 7 OR WS-WON = "Y"
            IF WS-CELL(WS-R, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R + 1, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R + 2, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R + 3, WS-C) = WS-PLAYER
                MOVE "Y" TO WS-WON
            END-IF
        END-PERFORM
    END-PERFORM.

CHECK-DIAGONAL-UP.
    PERFORM VARYING WS-R FROM 1 BY 1 UNTIL WS-R > 3 OR WS-WON = "Y"
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 4 OR WS-WON = "Y"
            IF WS-CELL(WS-R, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R + 1, WS-C + 1) = WS-PLAYER
                AND WS-CELL(WS-R + 2, WS-C + 2) = WS-PLAYER
                AND WS-CELL(WS-R + 3, WS-C + 3) = WS-PLAYER
                MOVE "Y" TO WS-WON
            END-IF
        END-PERFORM
    END-PERFORM.

CHECK-DIAGONAL-DOWN.
    PERFORM VARYING WS-R FROM 4 BY 1 UNTIL WS-R > 6 OR WS-WON = "Y"
        PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > 4 OR WS-WON = "Y"
            IF WS-CELL(WS-R, WS-C) = WS-PLAYER
                AND WS-CELL(WS-R - 1, WS-C + 1) = WS-PLAYER
                AND WS-CELL(WS-R - 2, WS-C + 2) = WS-PLAYER
                AND WS-CELL(WS-R - 3, WS-C + 3) = WS-PLAYER
                MOVE "Y" TO WS-WON
            END-IF
        END-PERFORM
    END-PERFORM.
