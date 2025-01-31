section .data
    width  equ 12
    height equ 12
    loop_iter_format db "%d", 12, 0
    grid_format db 10 , "%d:", 9, "%.10s", 0 ; format for, the number of printed char is width
    ;grid_format db 10 , "%d:", 9, "%.10s", 9, "%.10s", 0 ; debug format
    ; ANSI escape sequence
    reset_cursor db 0x1B, "[11A", 0x0D, 0 ; 0x1B ESC
                                                    ; "[#A" moves up # lines which is height in this case
                                                    ; 0x0D reverts cursor to beginning of line
                                                    ; null char, terminates string
    timespec:
        tv_sec  dq 1
        tv_nsec dq 0

section .bss
    grid: resb width * height
    grid_last_cycle: resb width * height

section .text
    global _start
    extern printf
    extern Sleep

sleep:
    mov rax, 35          ; syscall number for nanosleep
    lea rdi, [timespec]  ; pointer to timespec structure
    xor rsi, rsi         ; NULL for remaining time
    syscall              ; invoke syscall
    ret

init_grid:
    lea rdi, grid ; store pointer to the grid
    xor r8, r8
    ; Initialize the grid with underscores
    mov r9, width * height

.init_loop:
    mov [rdi + r8], byte '_'
    inc r8
    cmp r8, r9
    jl .init_loop

    ; create a glider in the top left corner
    mov [grid + (width * 1 + 3)], byte '#'
    mov [grid + (width * 2 + 1)], byte '#'
    mov [grid + (width * 2 + 3)], byte '#'
    mov [grid + (width * 3 + 2)], byte '#'
    mov [grid + (width * 3 + 3)], byte '#'

    ret

copy_grid:
    mov esi, grid
    mov edi, grid_last_cycle
    cld
    mov ecx, width*height
    rep movsb
    ret

print_grid:
    ; print loop iteration
    mov rdi, loop_iter_format
    mov rsi, r15
    ; call printf
    xor rax, rax
    call printf

    mov r12, 1 ;row index

.print_loop:
    mov rdi, grid_format
    mov rsi, r12

    mov r13, r12
    imul r13, width
    lea rcx, [grid + r13 + 1]; shift col by 1 to exclude the padding
    lea rdx, [grid_last_cycle + r13 + 1]; shift col by 1 to exclude the padding
    ;lea rdx, [grid + r13]; see the padding left

    ; call printf
    xor rax, rax
    call printf

    inc r12
    cmp r12, height - 1
    jl .print_loop

    ret

count_neighbours:
    ;r8 grid; r9 grid_last_cycle; r10 row index; r11 col index
    xor rax, rax
    mov rbx, qword-1; row index

.count_loop_row:
    mov rdx, qword-1; col index

.count_loop_col:
    ; r12: offset
    mov r12, r10
    imul r12, width
    add r12, r11

    ; r13 shifts row using rbx index information
    mov r13, rbx
    imul r13, width
    add r12, r13
    ; shift column
    add r12, rdx

    ; check if alive
    cmp byte [r9 + r12], '_'
    je .count_cell_is_dead
    inc rax; increase alive neighbour count

.count_cell_is_dead:
    inc rdx
    cmp rdx, 2
    jne .count_loop_col

    inc rbx
    cmp rbx, 2
    jne .count_loop_row
    ret

update_cell:
    mov r12, r10
    imul r12, width;
    add r12, r11

    ; less than two neighbours means death
    cmp byte [r9 + r12], '#'
    ;mov bl, [r9 + r12]
    ;cmp bl, '_'
    je .update_cell_is_alive

    cmp rax, 3
    je .update_cell_will_live
    ret ; cell stays dead

.update_cell_is_alive:
    ;dec rax; prevent counting itself as alive
    cmp rax, 3
    je .update_cell_will_live
    cmp rax, 4
    je .update_cell_will_live

.update_cell_will_die:
    mov byte [r8 + r12], '_'
    ret

.update_cell_will_live:
    mov byte [r8 + r12], '#'
    ret

update_grid:
    lea r8, grid ; update each cycle
    lea r9, grid_last_cycle ; use only as reference to count neighbors
    mov r10, 1; row index

.update_loop_outer:
    mov r11, 1; col index

.update_loop_inner:
    call count_neighbours ; output expected in rax
    call update_cell

    inc r11
    cmp r11, width - 1
    jl .update_loop_inner

    inc r10
    cmp r10, height - 1
    jl .update_loop_outer

    ret

_start:
    call init_grid
    call copy_grid
    xor r15, r15; limit iterations for testing

.game_loop:
    call print_grid
    call copy_grid
    call update_grid

    ; Reset cursor position using printf
    mov rdi, reset_cursor   ; Pointer to the escape sequence
    xor rax, rax            ; Clear rax for printf
    call printf             ; Call printf to print the escape sequence

    call sleep

    inc r15
    cmp r15, 10
    jnz .game_loop ;testing

    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; exit code 0
    syscall