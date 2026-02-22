FORMAT elf64 EXECUTABLE 3
SEGMENT READABLE EXECUTABLE WRITABLE

deb_mess db "FAIL",10
command_buffer rb 256
full_path_buf rb 512
buffer rb 200
pipefd rb 8
envp_ptr dq 0

MAX_ARGS=1000*8
BUFFER_SIZE=200

entry main
main:
        mov rax, [rsp]
        lea rsi, [rsp + 16 + rax*8]
        mov [envp_ptr], rsi

main_loop:
        call clean_buffer
        mov rax, 0
        mov rdi, 0
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        syscall
        cmp rax, 0
        jle exit_proc

        call handle_cd
        mov rax, 57
        syscall
        cmp rax, 0
        jne wait_parent
        jmp execute_chain

wait_parent:
        mov rax, 61
        mov rdi, -1
        xor rsi, rsi
        xor rdx, rdx
        xor r10, r10
        syscall
        jmp main_loop

exit_proc:
        mov rax, 60
        xor rdi, rdi
        syscall

fail:
        mov rax, 1
        mov rdi, 2
        mov rsi, deb_mess
        mov rdx, 5
        syscall
        mov rax, 60
        mov rdi, 1
        syscall

handle_cd:
        mov rsi, buffer
        cmp byte [rsi], 'c'
        jne .out
        cmp byte [rsi+1], 'd'
        jne .out
        add rsi, 3
        mov rdi, rsi
.fnl:
        cmp byte [rdi], 10
        je .t
        cmp byte [rdi], 0
        je .t
        inc rdi
        jmp .fnl
.t:
        mov byte [rdi], 0
        mov rax, 80
        mov rdi, rsi
        syscall
        pop rax
        jmp main_loop
.out:
        ret

clean_buffer:
        mov rcx, BUFFER_SIZE
        mov rdi, buffer
        xor al, al
        rep stosb
        ret

execute_chain:
        mov r12, buffer
.chain_loop:
        mov rsi, r12
.find_pipe:
        mov al, [rsi]
        cmp al, 10
        je .last_cmd
        cmp al, 0
        je .last_cmd
        cmp al, '|'
        je .found_pipe
        inc rsi
        jmp .find_pipe

.found_pipe:
        mov byte [rsi], 0
        lea r13, [rsi + 1]
.skip_s:
        cmp byte [r13], 32
        jne .p_go
        inc r13
        jmp .skip_s

.p_go:
        mov rax, 22
        mov rdi, pipefd
        syscall

        mov rax, 57
        syscall
        cmp rax, 0
        jne .p_parent

        mov rax, 33
        mov edi, dword [pipefd+4]
        mov rsi, 1
        syscall
        mov rax, 3
        mov edi, dword [pipefd]
        syscall
        mov rax, 3
        mov edi, dword [pipefd+4]
        syscall
        mov rsi, r12
        jmp do_exec

.p_parent:
        mov rax, 33
        mov edi, dword [pipefd]
        mov rsi, 0
        syscall
        mov rax, 3
        mov edi, dword [pipefd]
        syscall
        mov rax, 3
        mov edi, dword [pipefd+4]
        syscall
        mov r12, r13
        jmp .chain_loop

.last_cmd:
        mov byte [rsi], 0
        mov rsi, r12
        jmp do_exec

do_exec:
        mov r14, rsi
        mov rax, 9
        xor rdi, rdi
        mov rsi, MAX_ARGS
        mov rdx, 3
        mov r10, 34
        xor r8, r8
        xor r9, r9
        syscall
        mov rbx, rax
        mov rdx, rbx
        mov rsi, r14
.skip_initial_spaces:
        cmp byte [rsi], 32
        jne .start_parse
        inc rsi
        jmp .skip_initial_spaces
.start_parse:
        mov rdi, command_buffer
        mov [rdx], rdi
        add rdx, 8

.parse:
        mov al, [rsi]
        cmp al, 0
        je .done
        cmp al, 32
        je .s
        cmp al, 10
        je .done
        cmp al, '>'
        je .redir
        mov [rdi], al
        inc rdi
        inc rsi
        jmp .parse
.s:
        mov byte [rdi], 0
        inc rdi
        inc rsi
.ss:
        cmp byte [rsi], 32
        jne .sn
        inc rsi
        jmp .ss
.sn:
        cmp byte [rsi], 10
        je .done
        cmp byte [rsi], 0
        je .done
        mov [rdx], rdi
        add rdx, 8
        jmp .parse
.redir:
        mov byte [rdi], 0
        inc rsi
.rs:
        cmp byte [rsi], 32
        jne .rf
        inc rsi
        jmp .rs
.rf:
        mov rdi, rsi
.rl:
        cmp byte [rsi], 32
        je .re
        cmp byte [rsi], 10
        je .re
        cmp byte [rsi], 0
        je .re
        inc rsi
        jmp .rl
.re:
        mov byte [rsi], 0
        mov rax, 2
        mov rsi, 578
        mov rdx, 448
        syscall
        mov rdi, rax
        mov rax, 33
        mov rsi, 1
        syscall
        jmp .done

.done:
        mov byte [rdi], 0
        mov qword [rdx], 0
        
        mov rsi, command_buffer
        cmp byte [rsi], '/'
        je .direct
        cmp byte [rsi], '.'
        je .direct

        mov r8, [envp_ptr]
.f_path:
        mov rsi, [r8]
        test rsi, rsi
        jz .direct
        cmp dword [rsi], "PATH"
        jne .n_env
        cmp byte [rsi+4], "="
        je .p_found
.n_env:
        add r8, 8
        jmp .f_path

.p_found:
        add rsi, 5
        mov r9, rsi
.p_l:
        mov rdi, full_path_buf
.c_d:
        mov al, [r9]
        cmp al, ':'
        je .d_d
        cmp al, 0
        je .d_d
        mov [rdi], al
        inc rdi
        inc r9
        jmp .c_d
.d_d:
        mov byte [rdi], '/'
        inc rdi
        mov rsi, command_buffer
.c_c:
        mov al, [rsi]
        test al, al
        jz .att
        mov [rdi], al
        inc rdi
        inc rsi
        jmp .c_c
.att:
        mov byte [rdi], 0
        mov rax, 59
        mov rdi, full_path_buf
        mov rsi, rbx
        xor rdx, rdx
        syscall
        cmp byte [r9], 0
        je fail
        inc r9
        jmp .p_l

.direct:
        mov rax, 59
        mov rdi, command_buffer
        mov rsi, rbx
        xor rdx, rdx
        syscall
        jmp fail
