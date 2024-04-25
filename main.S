.include "io.S"
.include "syscalls.S"
.data
    listen_msg: .asciz "Server listen.\n"
    dbg: .asciz "Debug msg! "
.equ        AF_INET, 2
.equ        PORT, 3001
.text 
.globl      _start
exit:
    mov     $SYS_exit, %rax
    mov     $0, %rdi
    syscall

sock:
    mov     $SYS_socket, %rax
    mov     $AF_INET, %rdi # AF_INET
    mov     $1, %rsi
    mov     $0,%rdx
    syscall
    ret
bind:
#sizeof(sockaddr_in) = 16 
#   sa_family_t 2
#   in_port_t   2
#   in_addr     4 

    push     %rbp
    mov      %rsp, %rbp
    sub      $8, %rsp

    call     print_number

    mov      $SYS_bind,   %rax
    movw     $AF_INET,   (%rsp)
    movw     $3001, 2(%rsp)
    movl     $0, 4(%rsp)
    lea      (%rsp), %rsi
    mov      $8, %rdx
    syscall
    add      $8, %rsp
    pop      %rbp
    ret


_start:
    push    %rbp
    mov     %rsp, %rbp
    sub     $0x20, %rsp
    call    sock # return value/eax/fd of socket
    movl    %eax, (%rbp)
    mov     %rax, %rdi
    call    print_number
    mov     %rax, %rdi

    call    bind
    mov     %rax, %rdi
    call    print_number
    
    mov     $listen_msg, %rsi
    call    print_ln

    add     $0x20, %rsp
    pop     %rbp
    jmp     exit
