program connect_four
    implicit none

    integer, parameter :: rows = 6
    integer, parameter :: cols = 7
    character(len=1), parameter :: empty = '.'
    character(len=2), parameter :: players = 'XO'

    character(len=1) :: board(rows, cols)
    character(len=1) :: player
    integer :: column
    integer :: moves
    integer :: player_index
    logical :: finished

    call new_board(board)
    write (*, '(A)') '=== Connect Four ==='
    write (*, '(A)') 'Get four of your pieces in a row to win. Columns are numbered 1-7.'
    write (*, '(A)') ''
    call print_board(board)
    flush (6)

    moves = 0
    player_index = 1
    finished = .false.
    do while (.not. finished)
        player = players(player_index:player_index)
        column = ask_column(board, player)
        if (column < 0) then
            finished = .true.
        else
            board(lowest_empty_row(board, column), column) = player
            moves = moves + 1
            write (*, '(A)') ''
            call print_board(board)
            flush (6)
            if (has_four(board, player)) then
                write (*, '(A)') 'Player ' // player // ' wins!'
                flush (6)
                finished = .true.
            else if (moves == rows * cols) then
                write (*, '(A)') "It's a tie!"
                flush (6)
                finished = .true.
            else
                player_index = 3 - player_index
            end if
        end if
    end do

contains
    subroutine new_board(cells)
        character(len=1), intent(out) :: cells(rows, cols)
        cells = empty
    end subroutine new_board

    subroutine print_border()
        character(len=cols * 2 + 1) :: text
        text(1:1) = '+'
        text(2:cols * 2) = repeat('-', cols * 2 - 1)
        text(cols * 2 + 1:cols * 2 + 1) = '+'
        write (*, '(A)') text
    end subroutine print_border

    subroutine print_board(cells)
        character(len=1), intent(in) :: cells(rows, cols)
        character(len=cols * 2) :: labels
        character(len=cols * 2 + 1) :: text
        integer :: col
        integer :: position
        integer :: row

        labels = ' '
        do col = 1, cols
            labels(col * 2:col * 2) = achar(iachar('0') + col)
        end do
        write (*, '(A)') labels
        call print_border()
        do row = rows, 1, -1
            position = 1
            text(position:position) = '|'
            do col = 1, cols
                if (col > 1) then
                    position = position + 1
                    text(position:position) = ' '
                end if
                position = position + 1
                text(position:position) = cells(row, col)
            end do
            position = position + 1
            text(position:position) = '|'
            write (*, '(A)') text
        end do
        call print_border()
    end subroutine print_board

    function lowest_empty_row(cells, column) result(row)
        character(len=1), intent(in) :: cells(rows, cols)
        integer, intent(in) :: column
        integer :: row
        integer :: candidate

        row = -1
        do candidate = 1, rows
            if (cells(candidate, column) == empty) then
                row = candidate
                return
            end if
        end do
    end function lowest_empty_row

    function has_four(cells, player) result(found)
        character(len=1), intent(in) :: cells(rows, cols)
        character(len=1), intent(in) :: player
        logical :: found
        integer :: col
        integer :: offset
        integer :: row

        found = .false.
        do row = 1, rows
            do col = 1, cols - 3
                if (all([(cells(row, col + offset), offset = 0, 3)] == player)) then
                    found = .true.
                    return
                end if
            end do
        end do
        do row = 1, rows - 3
            do col = 1, cols
                if (all([(cells(row + offset, col), offset = 0, 3)] == player)) then
                    found = .true.
                    return
                end if
            end do
        end do
        do row = 1, rows - 3
            do col = 1, cols - 3
                if (all([(cells(row + offset, col + offset), offset = 0, 3)] == player)) then
                    found = .true.
                    return
                end if
            end do
        end do
        do row = 4, rows
            do col = 1, cols - 3
                if (all([(cells(row - offset, col + offset), offset = 0, 3)] == player)) then
                    found = .true.
                    return
                end if
            end do
        end do
    end function has_four

    function is_space(character_) result(space)
        character(len=1), intent(in) :: character_
        logical :: space
        integer :: code

        code = iachar(character_)
        space = character_ == ' ' .or. (code >= 9 .and. code <= 13)
    end function is_space

    function cleaned(text) result(token)
        character(len=*), intent(in) :: text
        character(len=len(text)) :: token
        integer :: first
        integer :: last

        first = 1
        last = len(text)
        do while (first <= last .and. is_space(text(first:first)))
            first = first + 1
        end do
        do while (last >= first .and. is_space(text(last:last)))
            last = last - 1
        end do
        if (first > last) then
            token = ''
        else
            token = text(first:last)
        end if
    end function cleaned

    function is_whole_number(token) result(whole)
        character(len=*), intent(in) :: token
        logical :: whole
        integer :: first
        integer :: last
        integer :: position

        last = len_trim(token)
        first = 1
        if (last > 0) then
            if (token(1:1) == '+' .or. token(1:1) == '-') then
                first = 2
            end if
        end if
        if (first > last) then
            whole = .false.
            return
        end if
        whole = .true.
        do position = first, last
            if (token(position:position) < '0' .or. token(position:position) > '9') then
                whole = .false.
                return
            end if
        end do
    end function is_whole_number

    function parse_value(token) result(value)
        character(len=*), intent(in) :: token
        integer :: value
        integer :: ios

        read (token, *, iostat=ios) value
        if (ios /= 0) then
            value = huge(value)
        end if
    end function parse_value

    function int_to_text(value) result(text)
        integer, intent(in) :: value
        character(len=16) :: text

        write (text, '(I0)') value
    end function int_to_text

    subroutine read_line(text, at_end)
        character(len=*), intent(out) :: text
        logical, intent(out) :: at_end
        integer :: ios

        text = ''
        read (*, '(A)', iostat=ios) text
        at_end = ios < 0
    end subroutine read_line

    function ask_column(cells, player) result(column)
        character(len=1), intent(in) :: cells(rows, cols)
        character(len=1), intent(in) :: player
        integer :: column
        character(len=1024) :: line
        character(len=1024) :: message
        character(len=1024) :: token
        integer :: value
        logical :: at_end

        do
            write (*, '(A)', advance='no') &
                'Player ' // player // ', choose a column (1-7): '
            flush (6)
            call read_line(line, at_end)
            if (at_end) then
                write (*, '(A)') ''
                write (*, '(A)') 'Input closed. Goodbye.'
                flush (6)
                column = -1
                return
            end if
            token = cleaned(line)
            if (len_trim(token) == 0) then
                message = 'Invalid input: no column entered.'
            else if (.not. is_whole_number(token)) then
                message = 'Invalid input: "' // trim(token) // '" is not a whole number.'
            else
                value = parse_value(trim(token))
                if (value < 1 .or. value > cols) then
                    message = 'Invalid input: "' // trim(token) // '" is out of range (1-7).'
                else if (lowest_empty_row(cells, value) < 0) then
                    message = 'Column ' // trim(int_to_text(value)) // ' is full.'
                else
                    column = value
                    return
                end if
            end if
            write (*, '(A)') ''
            write (*, '(A)') trim(message)
            flush (6)
        end do
    end function ask_column
end program connect_four
