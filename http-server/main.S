.include "io.S"
.include "syscalls.S"
.data
  .equ  SEEK_END,  2
  .equ  AF_INET,   2
  .equ  PORT,    47627
  .equ  SOL_SOCKET,  1
  .equ  SO_REUSEADDR,  2
  .equ  SO_REUSEPORT,  15

  bind_msg:   .asciz "Socket bound.\n"
  listen_msg: .asciz "Server listen.\n"
  dbg:        .asciz "Debug msg! "
  path:       .asciz "response.html",
  buffer:     .fill 128, 1
  address:
    .short AF_INET
    .short PORT
    .int 0
    .fill 0,8,0

.bss
file_desc: .space 4

.text 
.globl  _start
exit:
  mov   $SYS_exit,      %rax
  mov   $0,             %rdi
  syscall

sock:
  mov   $SYS_socket,    %rax
  mov   $AF_INET,       %rdi # AF_INET
  mov   $1,             %rsi
  mov   $0,             %rdx
  syscall
  ret

set_sock_opt:
  push  %rbp
  mov   %rsp,            %rbp
  sub   $12,             %rbp
  mov   $SYS_setsockopt, %rax
  mov   $SOL_SOCKET,     %rsi
  mov   $SO_REUSEADDR,   %rdx
  or    $SO_REUSEPORT,   %rdx

  lea   (%rbp),          %r10
  mov   $4, %r8
  syscall
 
  add   $12,             %rbp
  pop   %rbp
  ret

bind: 
# C Struct representation
#
#  sockaddr_in   16 
#   sa_family_t   2
#   in_port_t     2
#   in_addr       4 
#   void_bytes    8

  mov  $SYS_bind,         %rax
  
  lea  (address),         %rsi
  mov  $16, %rdx
  syscall
  ret

listen:
  mov   $SYS_listen,      %rax
  mov   $0, %rsi
  syscall
  ret
  
accept:
  mov  $SYS_accept,       %rax
  mov  $0, %rsi
  mov  $0, %rdx
  syscall
  ret

open:
  mov   $SYS_open,        %rax
  syscall
  ret

close_fd:
  mov   $SYS_close,       %rax
  syscall 
  ret
try_err:
  cmp   $0, %rax
  jne   print_err
  ret

print_err:
  mov   %rax,              %rdi
  mov   $SYS_exit,         %rax
  syscall

_start:
  push  %rbp
  mov   %rsp,              %rbp
  sub   $0x20,             %rsp

  call  sock # return value/eax/fd of socket
  movq  %rax,              (%rbp) # saving FD of socket
  mov   %rax,              %rdi
  call  print_number

  mov   (%rbp),            %rdi
  call  set_sock_opt # return value/eax/fd of socket
  call  try_err

  mov   (%rbp),            %rdi # using FD of socket
  call  bind
  call  try_err
  
  mov   $bind_msg,         %rsi
  call  print_ln

  mov   (%rbp),            %rdi # using FD of socket
  call  listen
  call  try_err

  mov   $listen_msg,       %rsi
  call  print

  mov   (%rbp),            %rdi # using FD of socket
  call  accept
  mov   %rax,              -8(%rbp)# FD of the new socket
  cmp   $0,                %rax
  jb    print_err


  mov   $path,             %rdi
  mov   $0,                %rsi
  mov   $0,                %rdx
  call  open 
  mov   %rax,              -16(%rbp)# saving FD the of file
  cmp   $0,                %rax
  jb    print_err


  mov   -16(%rbp),         %rdi
  mov   $0,                %rsi
  mov   $SEEK_END,         %rdx
  mov   $SYS_lseek,        %rax
  syscall
  mov   %rax,              -24(%rbp)# size the of file
  cmp   $0,                %rax
  jb    print_err

  mov   -16(%rbp),         %rdi
  mov   $0,                %rsi
  mov   $0,                %rdx
  mov   $SYS_lseek,        %rax
  syscall
  cmp   $0,                %rax
  jb    print_err


  mov   -8(%rbp),          %rdi#out_fd, FD of the new socket
  mov   -16(%rbp),         %rsi#in_fd, FD 0f the file
  mov   $0,                %rdx
  mov   -24(%rbp),         %r10#size of the buffer
  mov   $SYS_sendfile,     %rax
  syscall
  call  try_err


  mov   (%rbp),            %rdi # using FD of socket
  call  close_fd

  add   $0x20,             %rsp
  pop   %rbp
  jmp   exit
  
