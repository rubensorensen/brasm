%define SYSREAD    0
%define SYSWRITE   1
%define SYSOPEN    2
%define SYSCLOSE   3
%define SYSACCESS 21
%define SYSEXIT   60

%define EXITSUCCESS 0
%define EXITFAILURE 1

%define STDIN  0
%define STDOUT 1
%define STDERR 2

section .data
    buffer_size equ 4096
    no_argument_error db 'Error: No filename provided.', 0
    no_argument_error_len equ $ - no_argument_error
    file_not_exists_error db 'File does not exist.', 0
    file_not_exists_error_len equ $ - file_not_exists_error
    newline db 10

section .bss
    buffer resb buffer_size

section .text
    global _start

write_newline:
    ;; Inputs:
    ;; - rdi: File descriptor
    
    mov rsi, newline            ; ASCII code for newline
    mov rdx, 1                  ; Length of the newline character
    mov rax, SYSWRITE
    syscall
    ret
    
    
write_message:
    ;; Inputs:
    ;; - rdi: File descriptor
    ;; - rsi: Pointer to error message
    ;; - rdx: Length of error message
    
    mov rax, SYSWRITE
    syscall
    ret
    
exit_success:
    mov rdi, EXITSUCCESS
    jmp exit

exit_failure:
    mov rdi, EXITFAILURE
    jmp exit

exit:
    ;; Inputs:
    ;; - rdi: exit code
    mov rax, SYSEXIT
    syscall
    
_start:
    ;; Check to see that there are at least two command line arguments
    mov rdi, [rsp]              ; argc
    cmp rdi, 2                  ; Check if argc is at least 2
    jl .no_argument_error

    ;; Check that file exists and is readable
    mov rdi, [rsp + 16]       ; Filename provided in argv[1]
    mov rsi, 0                ; F_OK
    mov rax, SYSACCESS
    syscall
    cmp rax, 0                   ; Check if sys_open failed
    jne .file_not_exists_error   ; Jump to error handling if file doesn't exist
    
    ;; Open the file
    mov rdi, [rsp + 16]         ; Filename provided in argv[1]
    mov rsi, 0                  ; O_RDONLY
    mov rdx, 0                  ; Mode is ignored when opening an existing file
    mov rax, SYSOPEN            ; Syscall number for sys_open
    syscall
    mov r8, rax                 ; Save file descriptor

    ;; Read from the file
    mov rdi, r8                 ; File descriptor
    mov rsi, buffer
    mov rdx, buffer_size
    mov rax, SYSREAD            ; Syscall number for sys_read
    syscall

    ;; Write to stdout
    mov rdi, STDOUT             ; File descriptor for stdout
    mov rsi, buffer
    mov rdx, buffer_size
    call write_message

    ;; Close the file
    mov rdi, r8                 ; File descriptor
    mov rax, SYSCLOSE           ; Syscall number for sys_close
    syscall

    call exit_success
    
.no_argument_error:
    ;; Print the error to stderr
    mov rdi, STDERR
    mov rsi, no_argument_error
    mov rdx, no_argument_error_len
    call write_message
    call write_newline
    jmp exit_failure
    
.file_not_exists_error:
    ;; Print the error to stderr
    mov rdi, STDERR
    mov rsi, file_not_exists_error
    mov rdx, file_not_exists_error_len
    call write_message
    call write_newline
    jmp exit_failure
    
