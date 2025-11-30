FORMAT elf64 EXECUTABLE 3
SEGMENT READABLE EXECUTABLE WRITABLE
deb_mess db "FAIL"
ls_command db "/usr/bin/",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
command_buffer rb 256
buffer rb 200

MAX_ARGS=20000*8
BUFFER_SIZE=200
ST_SIZE_OFFSET=48
BIN_OFFSET=9

entry main
main:
        call clean_buffer
        mov rax, 0                    ; READ SYSCALL on STDIN TO BUFFER
        mov rdi, 0
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        syscall

        cmp rax, 0                   ; nothing read -> exit
        je exit

        call handle_cd_cmd

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

        mov rsi, ls_command
        mov rdi, command_buffer
        mov rdx, rax
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

        cmp al, '>'
        je redirection

        cmp al, 34
        je double_quote

        cmp al, 32
        je split
dont_skip_char:        
        mov [rdi], al
skip_char:
        inc rdi
skip_newline:
        inc rsi
        test al, al
        jnz copy_second
        add rdx, 8
exit_copy:
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
        mov rax, 1
        mov rdi, 1
        mov rsi, deb_mess
        mov rdx, 4
        syscall
        
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
split:
        cmp r15, 0
        jne dont_skip_char
        
        mov byte [rdi], 0

        inc rdi
        mov QWORD [rdx], rdi
        add rdx, 8
        dec rdi
        
        jmp skip_char

inc_rdi_and_skip_char:
        inc rdi
        jmp skip_char

handle_cd_cmd:
        ; check command starts with 'cd'

        mov r12, buffer
        cmp byte [r12], 'c'
        jne .rtrn

        inc r12
        cmp byte [r12], 'd'
        jne .rtrn

        inc r12
        inc r12
        
        mov r11, r12
        
.to_end_path:
        inc r11
        cmp byte [r11], 10
        jne .to_end_path
        mov byte [r11], 0

        ; call chdir to path
        mov rax, 80
        mov rdi, r12
        syscall

        cmp rax, -1
        je fail
        jmp main
.rtrn:
        ret
        
clean_buffer:
        mov r12, BUFFER_SIZE
        mov r11, buffer
.cloop:
        mov byte [r11], 0
        inc r11
        sub r12, 1

        cmp r12, 0
        jne .cloop

        ret

double_quote:
        not r15
        inc rsi
        jmp copy_second

redirection:
        cmp r15, 0
        jne dont_skip_char

        push rdi
        push rdx
        push r11
        push rsi


        mov rdi, rsi
        inc rdi
        inc rdi

        mov r11, rdi

.loop_to_newline:
        inc r11
        cmp BYTE [r11], 10
        jne .loop_to_newline

        mov BYTE [r11], 0

        mov rax, 2
        mov rsi, 578
        mov rdx, 448
        syscall


        cmp rax, -1
        je fail

        ; dup2 fd -> stdout
        mov rdi, rax
        mov rax, 33
        mov rsi, 1
        syscall

        cmp rax, -1
        je fail

        pop rsi
        pop r11
        pop rdx
        pop rdi

        sub rdx, 8
        jmp exit_copy

