section .data
    buffer_size equ 4096
    no_argument_error db 'Error: No filename provided.', 0
    file_not_exists_error db 'File does not exist.', 0
    newline db 10


section .bss
    buffer resb buffer_size

section .text
    global _start

_start:
    ;; Check to see that there are at least two command line arguments
    mov rdi, [rsp]              ; argc
    cmp rdi, 2                  ; Check if argc is at least 2
    jl .no_argument_error

    ;; Check that file exists and is readable
    mov rdi, [rsp + 16]       ; Filename provided in argv[1]
    mov rsi, 0                ; F_OK
    mov rax, 21               ; Syscall number for access
    syscall
    cmp rax, 0                   ; Check if sys_open failed
    jne .file_not_exists_error   ; Jump to error handling if file doesn't exist
    
    ;; Open the file
    mov rdi, [rsp + 16]         ; Filename provided in argv[1]
    mov rsi, 0                  ; O_RDONLY
    mov rdx, 0                  ; Mode is ignored when opening an existing file
    mov rax, 2                  ; Syscall number for sys_open
    syscall
    mov r8, rax                 ; Save file descriptor

    ;; Read from the file
    mov rdi, r8                 ; File descriptor
    mov rsi, buffer
    mov rdx, buffer_size
    mov rax, 0                  ; Syscall number for sys_read
    syscall

    ;; Write to stdout
    mov rdi, 1                  ; File descriptor for stdout
    mov rsi, buffer
    mov rdx, buffer_size
    mov rax, 1                  ; Syscall number for sys_write
    syscall

    ;; Close the file
    mov rdi, r8                 ; File descriptor
    mov rax, 3                  ; Syscall number for sys_close
    syscall

    call exit_success
    
.no_argument_error:
    ;; Print the error to stderr
    mov rdi, 2                             ; File descriptor for stderr
    mov rsi, no_argument_error             ; Error message to write
    mov rdx, 28                            ; Length of the error message
    mov rax, 1                             ; Syscall number for sys_write
    syscall

    ;; Print newline character to stderr
    mov rdi, 2                             ; file descriptor for stderr
    mov rsi, newline                       ; Newline ASCII code
    mov rdx, 1                             ; Length of the newline character
    mov rax, 1                             ; Syscall number for sys_write
    syscall

    call exit_failure
    
.file_not_exists_error:
    ;; Print the error to stderr
    mov rdi, 2                             ; File descriptor for stderr
    mov rsi, file_not_exists_error         ; Error message to write
    mov rdx, 20                            ; Length of the error message
    mov rax, 1                             ; Syscall number for sys_write
    syscall

    ;; Print newline character to stderr
    mov rdi, 2                             ; file descriptor for stderr
    mov rsi, newline                       ; Newline ASCII code
    mov rdx, 1                             ; Length of the newline character
    mov rax, 1                             ; Syscall number for sys_write
    syscall

    call exit_failure
    
    
exit_success:
    ; Exit the program
    mov rax, 60 ; syscall number for sys_exit
    xor rdi, rdi ; exit code 0
    syscall

exit_failure:
    ; Exit the program with failure
    mov rax, 60 ; syscall number for sys_exit
    mov rdi, 1 ; exit code 1 (indicating failure)
    syscall
