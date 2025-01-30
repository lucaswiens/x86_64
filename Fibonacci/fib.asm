section .data
    ; 0x9 tab; 0xA newline
    format db "%d:", 0x9,"%d", 0xA, 0  ; Format string for printf
    counter dq 15

section .bss
    result: resd 1;

section .text
    global _start
    extern printf

fib:
    ; if ecx is zero, just return 0
    test rcx, rcx ; Sets the ZF
    jz .ISZERO

    ; init stack frame
    push rbp
    mov rbp, rsp
    sub rsp, 4 ; allocate 4 bytes of memory on the stack

    ; inialize the first two fibonacci numbers
    mov rax, 0
    mov rbx, 1

    ; start the loop
    jnz .ISNOTZERO

.ISNOTZERO:
    mov [rbp-4], rax
    mov rax, rbx
    add rbx, [rbp-4]

    dec rcx
    jnz .ISNOTZERO

    mov [result], rax

    ; reset the stack frame
    mov rsp, rbp
    pop rbp
    ret

.ISZERO:
    mov dword [result], 0
    ret



print_result:
    ; Prepare the argument for printf
    mov rdi, format    ; First argument: pointer to the format string
    mov rsi, [counter]
    sub rsi, r12 ; Second argument: the integer to print (loop counter)
    mov rdx, [result]  ; Third argument: the integer to print (result)

    ; Call printf
    xor rax, rax ; calling conventions require rax to be zero as in this context it is the number of floating point arguments
    call printf
    ret

_start:
    ; print the first [counter] fibonacci numbers:
    mov r12, [counter]
    .CALCFIB:
    mov rcx, [counter]
    sub rcx, r12
    call fib
    call print_result
    dec r12
    jnz .CALCFIB

    ; Exit the program
    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; exit code 0
    syscall