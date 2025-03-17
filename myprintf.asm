section .text

global  myprintf

;=======================================================
;                 TRAMPLINE FOR CDeCL
;=======================================================
myprintf:
        pop r15

        push r9             ; push args for cdcle format
        push r8
        push rcx
        push rdx
        push rsi
        push rdi

        call cdcle_printf

        add rsp, 6 * 0x08
        push r15

        ret

cdcle_printf:
        push rbp
        mov rbp, rsp

        push rbx
        push r10

        xor rcx, rcx
        mov rbx, [rbp + 0x10]       ; format string

.str_loop:
        mov al, [rbx]
        test al, al
        jz .end

        cmp al, '%'
        je .handle_specifier

        push rax
        call putchar

        add rsp, 8
        inc rbx
        jmp .str_loop

.handle_specifier:
        inc rbx                     ; skip '%'
        mov al, [rbx]

        cmp al, '%'
        je .print_percent

        cmp al, 'd'
        je .print_decimal

        cmp al, 'c'
        je .print_char

        ;cmp al, 's'
        ;je .print_string

.print_percent:
        push '%'

        call putchar

        add rsp, 8
        inc rbx

        jmp .str_loop

.print_decimal:
        push qword [rbp + 0x18 + rcx * 8]

        call print_dec

        add rsp, 8
        inc rcx
        inc rbx

        jmp .str_loop

.print_char:
        push qword [rbp + 0x18 + rcx * 8]

        call putchar

        add rsp, 8
        inc rcx
        inc rbx

        jmp .str_loop

.end:
        mov rax, rcx                ; processed argument count

        pop r10
        pop rbx
        pop rbp

        ret

print_dec:
        push rbp
        mov rbp, rsp

        push rax
        push rcx
        push r10
        push r11
        push r12
        push rdx

        call clear_num_buffer

        mov rax, [rbp + 0x10]           ; rax <- number
        xor rcx, rcx                    ; rcx = 0
        xor r10, r10                    ; r10 = 0 (count non-sign 0)

        test eax, eax
        jns .nextdigit

        neg eax

        push '-'
        call putchar
        add rsp, 0x08

.nextdigit:
        mov edx, eax
        push rbx

        mov ebx, 10
        xor edx, edx
        div ebx

        pop rbx

        cmp edx, 0
        je .put_digit

        xor r10, r10
        dec r10

.put_digit:
        add edx, '0'
        mov BYTE [num_buffer + rcx], dl

.loop_end:
        inc r10
        inc rcx

        cmp rcx, BUFFER_SIZE
        jne .nextdigit

        cmp r10, BUFFER_SIZE                    ; trunctate unsignificant zeros
        jne .not_zero

        push '0'                                ; in case number is zero - write only zero
        call putchar
        add rsp, 0x08

        jmp .func_end

.not_zero:
        mov rcx, BUFFER_SIZE
        sub rcx, r10

.display_digit:
        lea r11, [num_buffer + rcx - 1]

        xor rax, rax
        mov al, BYTE [r11]

        push rax
        call putchar
        add rsp, 0x08

        loop .display_digit

.func_end:

        pop rdx
        pop r12
        pop r11
        pop r10
        pop rcx
        pop rax

        pop rbp

        ret

;puts:
;

putchar:
        push rbp
        mov rbp, rsp

        push rcx                        ; protect from syscall
        push r11

        push rax                        ; save regs
        push rdi
        push rsi
        push rbx
        push rdx

        mov rbx, [rbp + 0x10]
        mov BYTE [char_buffer], bl         ; fill buffer with char

        mov rax, 0x01                   ; write64 (rdi, rsi, rax)
        mov rdi, 0x01                   ; stdout fd
        mov rsi, char_buffer               ; curr string pos
        mov rdx, 0x01                   ; display only 1 char
        syscall

        pop rdx                         ; restore
        pop rbx
        pop rsi
        pop rdi
        pop rax

        pop r11
        pop rcx
        pop rbp

        ret

clear_num_buffer:
        push rcx
        mov rcx, BUFFER_SIZE

.next:
        mov BYTE [num_buffer + rcx - 1], 0
        loop .next

        pop rcx

        ret

section .data
        char_buffer: db 0x00
        BUFFER_SIZE equ 64
        num_buffer: times (BUFFER_SIZE) db 0x00