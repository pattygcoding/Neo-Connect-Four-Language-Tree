    .intel_syntax noprefix

    .equ DOT, 46
    .equ SPACE, 32
    .equ PIPE, 124
    .equ PLUS, 43
    .equ DASH, 45
    .equ NEWLINE, 10

    .text
    .globl main
# Play Connect Four on stdin/stdout until a player wins, the board fills up or
# the input stream ends.  Calls use the Microsoft x64 ABI, so each one reserves
# 32 bytes of shadow space and leaves rsp 16-byte aligned.
main:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32

    lea rdi, [rip+board]
    mov ecx, 42
    mov al, DOT
    rep stosb

    lea rcx, [rip+fmt_text]
    lea rdx, [rip+header]
    xor eax, eax
    call printf
    mov ecx, NEWLINE
    call putchar
    call print_board

    xor ebx, ebx
    xor r12d, r12d

game_loop:
    lea rax, [rip+players]
    movzx r13d, byte ptr [rax+r12]
    mov edi, r13d
    call ask_column
    test eax, eax
    js game_over
    mov r14d, eax
    mov edi, eax
    call lowest_empty_row
    imul eax, eax, 7
    add eax, r14d
    lea rcx, [rip+board]
    mov byte ptr [rcx+rax], r13b
    inc ebx
    mov ecx, NEWLINE
    call putchar
    call print_board
    mov edi, r13d
    call has_four
    test eax, eax
    jnz game_won
    cmp ebx, 42
    je game_tied
    mov eax, 1
    sub eax, r12d
    mov r12d, eax
    jmp game_loop

game_won:
    lea rcx, [rip+fmt_win]
    mov edx, r13d
    xor eax, eax
    call printf
    xor eax, eax
    jmp main_ret

game_tied:
    lea rcx, [rip+fmt_tie]
    xor eax, eax
    call printf
    xor eax, eax
    jmp main_ret

game_over:
    xor eax, eax

main_ret:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

# Print the +-------------+ rule, built from 7 column cells of 2 characters.
print_border:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 40

    mov ecx, PLUS
    call putchar
    mov ebx, 13
border_loop:
    mov ecx, DASH
    call putchar
    dec ebx
    jnz border_loop
    mov ecx, PLUS
    call putchar
    mov ecx, NEWLINE
    call putchar

    add rsp, 40
    pop rbx
    pop rbp
    ret

# Print the column labels, the board from the top row down, then the rule again.
print_board:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 32

    mov ecx, SPACE
    call putchar
    mov ebx, 1
labels_loop:
    cmp ebx, 7
    jg labels_done
    cmp ebx, 1
    jle labels_first
    mov ecx, SPACE
    call putchar
labels_first:
    lea ecx, [rbx+48]
    call putchar
    inc ebx
    jmp labels_loop
labels_done:
    mov ecx, NEWLINE
    call putchar
    call print_border

    mov ebx, 5
rows_loop:
    test ebx, ebx
    js rows_done
    mov ecx, PIPE
    call putchar
    xor r12d, r12d
cols_loop:
    cmp r12d, 7
    jge cols_done
    test r12d, r12d
    jz cols_first
    mov ecx, SPACE
    call putchar
cols_first:
    imul eax, ebx, 7
    add eax, r12d
    lea rcx, [rip+board]
    movzx ecx, byte ptr [rcx+rax]
    call putchar
    inc r12d
    jmp cols_loop
cols_done:
    mov ecx, PIPE
    call putchar
    mov ecx, NEWLINE
    call putchar
    dec ebx
    jmp rows_loop
rows_done:
    call print_border

    add rsp, 32
    pop r12
    pop rbx
    pop rbp
    ret

# Return the lowest empty row of column edi, or -1 when that column is full.
lowest_empty_row:
    xor eax, eax
empty_row_loop:
    cmp eax, 6
    jge empty_row_full
    mov ecx, eax
    imul ecx, ecx, 7
    add ecx, edi
    lea rdx, [rip+board]
    cmp byte ptr [rdx+rcx], DOT
    je empty_row_done
    inc eax
    jmp empty_row_loop
empty_row_full:
    mov eax, -1
empty_row_done:
    ret

# Return 1 when four edi pieces run from (esi, edx) along (r8d, r9d).  Callers
# only pass start cells that keep all four steps on the board.
check_dir:
    xor r10d, r10d
step_loop:
    cmp r10d, 4
    jge step_yes
    mov eax, r10d
    imul eax, r8d
    add eax, esi
    imul eax, eax, 7
    mov ecx, r10d
    imul ecx, r9d
    add ecx, edx
    add eax, ecx
    lea r11, [rip+board]
    movzx ecx, byte ptr [r11+rax]
    cmp ecx, edi
    jne step_no
    inc r10d
    jmp step_loop
step_yes:
    mov eax, 1
    ret
step_no:
    xor eax, eax
    ret

# Return 1 when edi has four in a row horizontally, vertically or diagonally.
has_four:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32
    mov r14d, edi

    xor ebx, ebx
h_row_loop:
    cmp ebx, 6
    jge v_row_start
    xor r12d, r12d
h_col_loop:
    cmp r12d, 4
    jge h_col_done
    mov edi, r14d
    mov esi, ebx
    mov edx, r12d
    xor r8d, r8d
    mov r9d, 1
    call check_dir
    test eax, eax
    jnz four_found
    inc r12d
    jmp h_col_loop
h_col_done:
    inc ebx
    jmp h_row_loop

v_row_start:
    xor ebx, ebx
v_row_loop:
    cmp ebx, 3
    jge d1_row_start
    xor r12d, r12d
v_col_loop:
    cmp r12d, 7
    jge v_col_done
    mov edi, r14d
    mov esi, ebx
    mov edx, r12d
    mov r8d, 1
    xor r9d, r9d
    call check_dir
    test eax, eax
    jnz four_found
    inc r12d
    jmp v_col_loop
v_col_done:
    inc ebx
    jmp v_row_loop

d1_row_start:
    xor ebx, ebx
d1_row_loop:
    cmp ebx, 3
    jge d2_row_start
    xor r12d, r12d
d1_col_loop:
    cmp r12d, 4
    jge d1_col_done
    mov edi, r14d
    mov esi, ebx
    mov edx, r12d
    mov r8d, 1
    mov r9d, 1
    call check_dir
    test eax, eax
    jnz four_found
    inc r12d
    jmp d1_col_loop
d1_col_done:
    inc ebx
    jmp d1_row_loop

d2_row_start:
    mov ebx, 3
d2_row_loop:
    cmp ebx, 6
    jge four_none
    xor r12d, r12d
d2_col_loop:
    cmp r12d, 4
    jge d2_col_done
    mov edi, r14d
    mov esi, ebx
    mov edx, r12d
    mov r8d, -1
    mov r9d, 1
    call check_dir
    test eax, eax
    jnz four_found
    inc r12d
    jmp d2_col_loop
d2_col_done:
    inc ebx
    jmp d2_row_loop

four_found:
    mov eax, 1
    jmp four_ret
four_none:
    xor eax, eax
four_ret:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

# Return 1 only for an optional sign followed by at least one ASCII digit.
is_whole_number:
    movzx eax, byte ptr [rdi]
    cmp al, PLUS
    je number_sign
    cmp al, DASH
    jne number_first
number_sign:
    inc rdi
    movzx eax, byte ptr [rdi]
number_first:
    test al, al
    jz number_no
    cmp al, 48
    jb number_no
    cmp al, 57
    ja number_no
number_loop:
    inc rdi
    movzx eax, byte ptr [rdi]
    test al, al
    jz number_yes
    cmp al, 48
    jb number_no
    cmp al, 57
    ja number_no
    jmp number_loop
number_yes:
    mov eax, 1
    ret
number_no:
    xor eax, eax
    ret

# Trim leading and trailing whitespace in place and return the new start.
strip:
strip_lead:
    movzx eax, byte ptr [rdi]
    test al, al
    jz strip_done
    cmp al, SPACE
    je strip_lead_advance
    cmp al, 9
    jb strip_lead_done
    cmp al, 13
    ja strip_lead_done
strip_lead_advance:
    inc rdi
    jmp strip_lead
strip_lead_done:
    mov rsi, rdi
strip_end:
    cmp byte ptr [rsi], 0
    je strip_back
    inc rsi
    jmp strip_end
strip_back:
    cmp rsi, rdi
    jbe strip_term
    movzx eax, byte ptr [rsi-1]
    cmp al, SPACE
    je strip_back_advance
    cmp al, 9
    jb strip_term
    cmp al, 13
    ja strip_term
strip_back_advance:
    dec rsi
    jmp strip_back
strip_term:
    mov byte ptr [rsi], 0
strip_done:
    mov rax, rdi
    ret

# Read one line without its newline into linebuf; rax is that buffer, or 0 when
# the stream is already at end of input.
read_line:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 32
    xor ebx, ebx
    xor r12d, r12d
read_loop:
    call getchar
    cmp eax, -1
    je read_eof
    mov r12d, 1
    cmp eax, NEWLINE
    je read_finish
    cmp ebx, 4095
    jae read_loop
    lea rcx, [rip+linebuf]
    mov byte ptr [rcx+rbx], al
    inc ebx
    jmp read_loop
read_eof:
    test r12d, r12d
    jz read_null
read_finish:
    lea rcx, [rip+linebuf]
    mov byte ptr [rcx+rbx], 0
    mov rax, rcx
    jmp read_ret
read_null:
    xor eax, eax
read_ret:
    add rsp, 32
    pop r12
    pop rbx
    pop rbp
    ret

# Prompt until a legal column is entered, reprinting the board's rule on every
# rejection.  Returns the zero-based column, or -1 when the input stream ends.
ask_column:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32
    mov ebx, edi

ask_loop:
    lea rcx, [rip+fmt_choose]
    mov edx, ebx
    xor eax, eax
    call printf
    xor ecx, ecx
    call fflush
    call read_line
    test rax, rax
    jz ask_eof
    mov rdi, rax
    call strip
    mov r12, rax
    cmp byte ptr [r12], 0
    je ask_empty
    mov rdi, r12
    call is_whole_number
    test eax, eax
    jz ask_not_number

    xor r13d, r13d
    mov rsi, r12
    movzx eax, byte ptr [rsi]
    cmp al, DASH
    jne ask_plus
    mov r13d, 1
    inc rsi
    jmp ask_parse
ask_plus:
    cmp al, PLUS
    jne ask_parse
    inc rsi
ask_parse:
    xor r14d, r14d
# Accumulate the digits saturating at LONG_MAX, which is all the range check
# needs: anything that overflows is reported as out of range by its token.
ask_digit:
    movzx eax, byte ptr [rsi]
    test al, al
    jz ask_parsed
    sub eax, 48
    movabs rcx, 1844674407370955161
    cmp r14, rcx
    ja ask_saturate
    lea r14, [r14+r14*4]
    add r14, r14
    add r14, rax
    jc ask_saturate
    inc rsi
    jmp ask_digit
ask_saturate:
    movabs r14, 0x7fffffffffffffff
ask_parsed:
    test r13d, r13d
    jnz ask_range
    cmp r14, 1
    jb ask_range
    cmp r14, 7
    ja ask_range
    lea edi, [r14]
    dec edi
    call lowest_empty_row
    cmp eax, 0
    jl ask_full
    lea eax, [r14]
    dec eax
    jmp ask_ret

ask_full:
    lea rcx, [rip+fmt_full]
    mov edx, r14d
    xor eax, eax
    call printf
    jmp ask_next
ask_range:
    lea rcx, [rip+fmt_range]
    mov rdx, r12
    xor eax, eax
    call printf
    jmp ask_next
ask_not_number:
    lea rcx, [rip+fmt_not_number]
    mov rdx, r12
    xor eax, eax
    call printf
    jmp ask_next
ask_empty:
    lea rcx, [rip+fmt_empty]
    xor eax, eax
    call printf
ask_next:
    xor ecx, ecx
    call fflush
    jmp ask_loop
ask_eof:
    lea rcx, [rip+fmt_bye]
    xor eax, eax
    call printf
    xor ecx, ecx
    call fflush
    mov eax, -1
ask_ret:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    .section .rdata,"dr"
header:
    .asciz "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n"
players:
    .ascii "XO"
fmt_text:
    .asciz "%s"
fmt_choose:
    .asciz "Player %c, choose a column (1-7): "
fmt_not_number:
    .asciz "\nInvalid input: \"%s\" is not a whole number.\n"
fmt_range:
    .asciz "\nInvalid input: \"%s\" is out of range (1-7).\n"
fmt_empty:
    .asciz "\nInvalid input: no column entered.\n"
fmt_full:
    .asciz "\nColumn %d is full.\n"
fmt_win:
    .asciz "Player %c wins!\n"
fmt_tie:
    .asciz "It's a tie!\n"
fmt_bye:
    .asciz "\nInput closed. Goodbye.\n"

    .section .bss,"bw"
    .align 8
board:
    .space 42
    .align 8
linebuf:
    .space 4096
