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

%define argc [rsp]
%define argv(n) [rsp + 8 + 8*n]

section .data
    buffer_size equ 4096
    no_argument_error db 'Error: No filename provided.', 0
    no_argument_error_len equ $ - no_argument_error
    file_not_exists_error db 'File does not exist.', 0
    file_not_exists_error_len equ $ - file_not_exists_error
    usage_first db 'usage: ', 0
    usage_first_len equ $ - usage_first
    usage_last db ' filename', 0
    usage_last_len equ $ - usage_last
    newline db 10

section .bss
    buffer resb buffer_size

section .text
    global _start
    
exit_success:
    mov rdi, EXITSUCCESS
    jmp exit

exit_failure:
    mov rdi, EXITFAILURE
    jmp exit

exit:
    ;; Inputs:
    ;; - rdi: Exit code
    mov rax, SYSEXIT
    syscall

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
    ;; - rsi: Pointer to message
    ;; - rdx: Length of message
    
    mov rax, SYSWRITE
    syscall
    ret
        
_start:
    mov r8, [rsp]               ; Store argc
    
    add rsp, 8                  ; Nest arg
    mov r9, [rsp]               ; Store argv[0]
    
    ;; Check to see that there are at least two command line arguments
    mov rdi, r8
    cmp rdi, 2                 ; Check if argc is at least 2
    jl .no_argument_error
    
    add rsp, 8                  ; Next arg
    mov r10, [rsp]              ; Store argv[1]

    
    ;; r8  : argc
    ;; r9  : program name
    ;; r10 : brainfuck file name
    
    ;; Check that file exists and is readable
    mov rdi, r10
    mov rsi, 0                ; F_OK
    mov rax, SYSACCESS
    syscall
    cmp rax, 0                   ; Check if sys_open failed
    jne .file_not_exists_error   ; Jump to error handling if file doesn't exist
    
    ;; Open the file
    mov rdi, r10         ; Filename provided in argv[1]
    mov rsi, 0                  ; O_RDONLY
    mov rdx, 0                  ; Mode is ignored when opening an existing file
    mov rax, SYSOPEN            ; Syscall number for sys_open
    syscall
    mov r11, rax                 ; Save file descriptor

    ;; Read from the file
    mov rdi, r11                 ; File descriptor
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
    mov rdi, r11                 ; File descriptor
    mov rax, SYSCLOSE           ; Syscall number for sys_close
    syscall

    call exit_success
    
.no_argument_error:
    ;; Print usage
    mov rdi, STDERR
    mov rsi, usage_first
    mov rdx, usage_first_len
    call write_message
    
    mov rdi, r9
    call get_string_length
    mov rdx, rax
    mov rdi, STDERR
    mov rsi, r9
    call write_message

    mov rdi, STDERR
    mov rsi, usage_last
    mov rdx, usage_last_len
    call write_message

    mov rdi, STDERR
    call write_newline

    mov rdi, STDERR
    call write_newline
    
    ;; Print the error
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

get_string_length:
    ;; Input:
    ;; - rdi: Pointer to string
    ;; Output:
    ;; - rax: String length
    xor rax, rax                ; Initialize length to 0
.find_length_loop:
    cmp byte [rdi], 0           ; Check for null terminator
    je  .found_length            ; If null terminator, exit the loop
    inc rdi                     ; Move to the next character
    inc rax                     ; Increment the length
    jmp .find_length_loop
.found_length:
    ret
