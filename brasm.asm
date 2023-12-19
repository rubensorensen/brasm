section .rodata
    msg db 'Hello, world!',0xa  ; Hello world string
    len equ $ - msg             ; Length of string

section .text
    global _start               ; Export _start, our entrypoint

_start:                         ; Entry point
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; file descriptor (stdout)
    mov ecx, msg                ; message to write
    mov edx, len                ; message length
    int 0x80                    ; call kernel

    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; process' exit code
    int 0x80                    ; call kernel
