section .rodata
jump_table:
                        dq case_percent         ; %
times ('b' - '%' - 1)   dq case_default         ; skip useless [38-97 ASCII]
                        dq case_b               ; %b
                        dq case_c               ; %c
                        dq case_d               ; %d

times ('o' - 'd' - 1)   dq case_default         ; skip useless [101-111 ASCII]
                        dq case_o               ; %o

times ('s' - 'o' - 1)   dq case_default         ; skip useless [112-114 ASCII]

                        dq case_s               ; %s

times ('x' - 's' - 1)   dq case_default         ; skip useless [115-119 ASCII]

                        dq case_x               ; %x

                        dq case_default         ; default case for errors


section .text

global  MyPrintf

;=======================================================
;                 TRAMPLINE FOR CDeCL
;=======================================================
MyPrintf:
        pop r15

        push r9                                 ; push args for cdcle format
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
        mov  rbp, rsp

        push rbx
        push r10

        xor rcx, rcx
        mov rbx, [rbp + 0x10]                   ; format string

.str_loop:
        cmp BYTE [rbx], '%'                     ; check if symb is specifier
        je .specifier_encounter

        push rcx                                ; protect from syscall

        mov rax, 0x01                           ; write64 (rdi, rsi, rax)
        mov rdi, 0x01                           ; stdout fd
        mov rsi, rbx                            ; curr string pos
        mov rdx, 0x01                           ; display only 1 char
        syscall

        pop rcx

.str_loop_end:
        inc rbx                                 ; next symbol

        cmp BYTE [rbx], 0                       ; stop if encounter null terminator
        jne .str_loop
        jmp .end

.specifier_encounter:
        inc rbx                         ; skip % symbol

                                        ; value of specifier parameter in stack
        push QWORD [rbp + rcx * 0x08 + 0x18]
        push rbx                        ; specifier symbol

        call handle_specifier

        add  rsp, 2 * 0x08              ; clean stack

        cmp BYTE [rbx], '%'             ; <-- FORMER BUG, KEEP AN EYE ON THIS PLACE
        jne .spend_stack_param

        jmp .str_loop_end

.spend_stack_param:
        inc rcx                         ; increase number of processed specifiers
        jmp .str_loop_end

        jmp .end                   ; kinda silly precaution

.end:

        mov rax, rcx                    ; return value

        pop r10                         ; restore
        pop rbx
        pop rcx

        pop rbp

        ret

handle_specifier:
        push rbp
        mov  rbp, rsp

        push rbx
        push rcx

        mov rbx, [rbp + 0x10]                   ; spec symbol

        mov cl, BYTE [rbx]
        xor rbx, rbx
        mov bl, cl

        cmp rbx, 'x'                            ; the greates ASCII code among all spec symbs
        ja case_default

        cmp rbx, '%'                            ; the least ASCII code
        jb case_default

        jmp [jump_table + 8 * (rbx - '%')]      ; jump with jump_table

L1:  ; & ASCII 37
L2:  ; '
L3:  ; (
L4:  ; )
L5:  ; *
L6:  ; +
L7:  ; ,
L8:  ; -
L9:  ; .
L10: ; /
L11: ; 0
L12: ; 1
L13: ; 2
L14: ; 3
L15: ; 4
L16: ; 5
L17: ; 6
L18: ; 7
L19: ; 8
L20: ; 9
L21: ; :
L22: ; ;
L23: ; <
L24: ; =
L25: ; >
L26: ; ?
L27: ; @
L28: ; A
L29: ; B
L30: ; C
L31: ; D
L32: ; E
L33: ; F
L34: ; G
L35: ; H
L36: ; I
L37: ; J
L38: ; K
L39: ; L
L40: ; M
L41: ; N
L42: ; O
L43: ; P
L44: ; Q
L45: ; R
L46: ; S
L47: ; T
L48: ; U
L49: ; V
L50: ; W
L51: ; X
L52: ; Y
L53: ; Z
L54: ; [
L55: ; \
L56: ; ]
L57: ; ^
L58: ; _
L59: ; `
L60: ; a
L64: ; e
L65: ; f
L66: ; g
L67: ; h
L68: ; i
L69: ; j
L70: ; k
L71: ; l
L72: ; m
L73: ; n
L75: ; p
L76: ; q
L77: ; r
L79: ; t
L80: ; u
L81: ; v
L82: ; w ASCII 119

case_default:
        ; aboba

        jmp switch_end

case_percent:
        push '%'
        call putchar

        add rsp, 8
        jmp switch_end

case_b:
        push '0'                         ; write prefix
        call putchar
        add rsp, 0x08

        push 'b'
        call putchar
        add rsp, 0x08

        ; TODO print binary num

        jmp switch_end

case_c:
        push QWORD [rbp + 0x18]
        call putchar

        add rsp, 0x08

        jmp switch_end

case_d:
        push QWORD [rbp + 0x18]
        call print_dec

        add rsp, 0x08

        jmp switch_end

case_o:
        push '0'                         ; write prefix
        call putchar
        add rsp, 0x08

        push 'o'
        call putchar
        add rsp, 0x08

        ; TODO print oct num

        jmp switch_end

case_s:
        ;push QWORD [rbp + 0x18]
        ;call puts_cdecl
        ; TODO puts_cdecl

        add rsp, 0x08

        jmp switch_end

case_x:
        push '0'                         ; write prefix
        call putchar
        add rsp, 0x08

        push 'x'
        call putchar
        add rsp, 0x08

        ; TODO print hex num

        jmp switch_end

switch_end:
        pop rcx
        pop rbx
        pop rbp

        ret

print_dec:
        push rbp
        mov  rbp, rsp

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
