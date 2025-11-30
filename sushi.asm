FORMAT elf64 EXECUTABLE 3
SEGMENT READABLE EXECUTABLE WRITABLE
debug_mess db "DEBUG",10
ls_command db "/usr/bin/",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
command_buffer rb 256
buffer rb 100

MAX_ARGS=20*8
BUFFER_SIZE=100
ST_SIZE_OFFSET=48
BIN_OFFSET=9

entry main
main:
        mov rax, 0                    ; READ SYSCALL on STDIN TO BUFFER
        mov rdi, 0
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        syscall

        cmp rax, 0                   ; nothing read -> exit
        je exit

        mov rax, 57                  ; fork
        syscall

        cmp rax, 0
        jl fail

        cmp rax, 0
        jne wait_and_main

        mov rax, 9
        mov rdi, 0
        mov rsi, MAX_ARGS
        mov rdx, 3
        mov r10, 34
        mov r8, 0
        mov r9, 0
        syscall

        cmp rax, 0xffffffffffffffff
        je fail

        push rax 

        mov rsi, ls_command
        mov rdi, command_buffer
        pop rdx
        mov r12, rdx

copy_first:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        test al, al
        jnz copy_first

        dec rdi  

        mov rsi, buffer

        mov QWORD [rdx], rdi
        add rdx, 8
copy_second:
        mov al, [rsi]
        cmp al, 10
        je skip_newline

        cmp al, 32
        je split
        
        mov [rdi], al
skip_char:
        inc rdi
skip_newline:
        inc rsi
        test al, al
        jnz copy_second

        add rdx, 8
        mov QWORD [rdx], 0

        mov r10, 0
        mov r11, 0

        mov rax, 59
        mov rdi, command_buffer
        mov rsi, r12
        mov rdx, 0
        syscall

        cmp rax, -1
        je fail

        mov rax, 60
        mov rdi, 0
        syscall
        
        jmp main
exit:
        mov rax, 60
        mov rdi, 0
        syscall
fail:
        mov rax, 60
        mov rdi, 1
        syscall
wait_and_main:
        mov rax, 61
        mov rdi, 0
        mov rsi, 0
        mov rdx, 0
        mov r10, 0
        syscall

        jmp main
debug:
        push rax
        push rdi
        push rsi
        push rdx

        mov rax, 1
        mov rdi, 1
        mov rsi, debug_mess
        mov rdx, 6
        syscall

        pop rdx
        pop rsi
        pop rdi
        pop rax
        ret

split:
        mov byte [rdi], 0

        inc rdi
        mov QWORD [rdx], rdi
        add rdx, 8
        dec rdi
        
        jmp skip_char 
