;=======================================================
;                    READ ONLY DATA
;=======================================================
section .rodata

error_msg:              db "[Unknown format specifier: %", 0
error_msg_len           equ $ - error_msg - 1
close_bracket_msg:      db "]", 0
close_bracket_len       equ $ - close_bracket_msg - 1
space:                  db ' '

;=======================================================
;                      JUMP TABLE
;=======================================================
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
extern ArgumentCount                            ; My extern function

;=======================================================
;                 MY PRINTF FUNCTION
;       %%, %c, %d, %s, %b, %o, %x specificators
;=======================================================

global MyPrintf

;=======================================================
;                 TRAMPLINE FOR CDECL
;=======================================================
MyPrintf:
        push r15                                ; return address

        push r9                                 ; push args for cdecl format
        push r8
        push rcx
        push rdx
        push rsi
        push rdi

        call cdcle_printf                       ; call MyPrintf with CDECL

        add rsp, 6 * 0x08
        pop r15                                 ; restore

        ret

cdcle_printf:
        push rbp
        mov  rbp, rsp

        push rcx                                ; save regs
        push rbx
        push r10

        xor r10, r10                            ; r10 = 0
        xor rcx, rcx                            ; rcx = 0
        mov rbx, QWORD [rbp + 0x10]             ; rbx = format string

.str_loop:
        cmp BYTE [rbx], '%'                     ; check if symb is specifier
        je .specifier_encounter

        push rcx                                ; save rcx
        movzx rax, BYTE [rbx]                   ; read curr symbol

        push rax                                ; added simpe char (letter, digit and ...)
        call putchar
        add rsp, 8

        pop rcx                                 ; unsave rcx
        jmp .str_loop_end

.str_loop_end:
        inc rbx                                 ; next symbol

        cmp BYTE [rbx], 0                       ; stop if encounter null terminator
        jne .str_loop
        jmp .end

.specifier_encounter:
        inc rbx                                 ; skip % symbol

        push QWORD [rbp + rcx * 0x08 + 0x18]    ; value of specifier parameter in stack
        push rbx                                ; specifier symbol

        call handle_specifier

        add rsp, 2 * 0x08                       ; clean stack

        cmp BYTE [rbx], '%'
        jne .spend_stack_param

        jmp .str_loop_end

.spend_stack_param:
        inc rcx                                 ; increase number of processed specifiers
        jmp .str_loop_end

        jmp .end

.end:
        call flush_buffer

        push rcx
        mov  rdi, rcx                           ; read specifiers count
        call ArgumentCount                      ; call extern function
        pop rcx

        mov rax, rcx                            ; return value

        pop r10                                 ; restore
        pop rbx
        pop rcx

        pop rbp

        ret

;=======================================================
;                PROCESSING SPECIFIERS
;=======================================================
handle_specifier:
        push rbp
        mov  rbp, rsp

        push rbx
        push rcx

        mov rbx, [rbp + 0x10]                   ; specificator 

        mov cl, BYTE [rbx]
        xor rbx, rbx
        mov bl, cl

        ; if ASCII code not in [ascii(%); ascii(x)] => case_default

        cmp rbx, '%'                            ; the least ASCII code
        jb case_default
        cmp rbx, 'x'                            ; the greates ASCII code among all spec symbs
        ja case_default

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

; in default case MyPrintf show which specificator it do not recognize
case_default:
        push rax                        ; save regs
        push rbx
        push rsi
        push rdx

        mov rsi, error_msg

.error_loop:
        movzx eax, BYTE [rsi]
        test al, al
        jz .error_spec_output

        push rax
        call putchar
        add rsp, 8
        inc rsi
        jmp .error_loop

.error_spec_output:
        movzx eax, bl

        push rax
        call putchar
        add rsp, 8

        mov rsi, close_bracket_msg

.close_loop:
        movzx eax, BYTE [rsi]
        test al, al
        jz .end_error

        push rax
        call putchar
        add rsp, 8

        inc rsi
        jmp .close_loop

.end_error:
        pop rdx
        pop rsi
        pop rbx
        pop rax

        jmp switch_end

case_percent:
        push '%'
        call putchar                     ; add % in buffer

        add rsp, 8
        jmp switch_end

case_b:
        push '0'                         ; <-----\
        call putchar                     ;       |
        add rsp, 0x08                    ;       |
                                         ;       | <- write prefix
        push 'b'                         ;       |
        call putchar                     ;       |
        add rsp, 0x08                    ; <-----/

        push 2                           ; push base = 2
        push QWORD [rbp + 0x18]          ; push number
        call convert_to_base             ; call converter num in need base
        add rsp, 16

        jmp switch_end

case_c:
        push QWORD [rbp + 0x18]          ; push symbol
        call putchar                     ; call buffered putchar
        add rsp, 0x08

        jmp switch_end

case_d:
        push QWORD [rbp + 0x18]         ; push number
        call print_dec                  ; add number ib buffer
        add rsp, 0x08

        jmp switch_end

case_o:
        push '0'                         ; <-----\
        call putchar                     ;       |
        add rsp, 0x08                    ;       |
                                         ;       | <- write prefix
        push 'o'                         ;       |
        call putchar                     ;       |
        add rsp, 0x08                    ; <-----/

        push 8                           ; push base = 8
        push QWORD [rbp + 0x18]          ; push number
        call convert_to_base             ; call converter num in need base
        add rsp, 16

        jmp switch_end

case_s:
        push QWORD [rbp + 0x18]
        call puts

        add rsp, 0x08

        jmp switch_end

case_x:
        push '0'                         ; <-----\
        call putchar                     ;       |
        add rsp, 0x08                    ;       |
                                         ;       | <- write prefix
        push 'x'                         ;       |
        call putchar                     ;       |
        add rsp, 0x08                    ; <-----/

        push 16                          ; push base = 16
        push QWORD [rbp + 0x18]          ; push number
        call convert_to_base             ; call converter num in need base
        add rsp, 16

        jmp switch_end

switch_end:
        pop rcx                          ; recover regs
        pop rbx
        pop rbp

        ret

;=======================================================
;                  DECIMAL NUMBER (%d)
;=======================================================
print_dec:
        push rbp
        mov  rbp, rsp

        push rax                        ; save regs
        push rcx
        push r10
        push r11
        push r12
        push rdx

        call clear_num_buffer           ; clear buffer for numbers

        mov rax, [rbp + 0x10]           ; rax <- number
        xor rcx, rcx                    ; rcx = 0
        xor r10, r10                    ; r10 = 0 (count non-sign 0)

        test eax, eax
        jns .nextdigit

        neg eax

        push '-'                        ; add minus ('-') in buffer
        call putchar
        add rsp, 0x08

.nextdigit:
        mov  edx, eax
        push rbx

        mov ebx, 10
        xor edx, edx
        div ebx

        pop rbx

        cmp edx, 0                      ; div while != 0
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

        cmp r10, BUFFER_SIZE
        jne .not_zero

        push '0'                                ; zero => added zero (auf!)
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
        pop rdx                         ; recover regs
        pop r12
        pop r11
        pop r10
        pop rcx
        pop rax

        pop rbp

        ret

;=======================================================
;                 WORK WITH STRING (%s)
;=======================================================
puts:
        push rbp
        mov  rbp, rsp

        push rcx                        ; save regs
        push r11

        push rax
        push rdi
        push rsi
        push rbx
        push rdx

        mov rbx, [rbp + 0x10]

.loop:
        mov al, [rbx]
        test al, al
        jz .add_space                   ; NO add space symbol

        push rax                        ; send symbol in putchar
        call putchar                    ; call puthcar for each symbol
        add rsp, 8

        inc rbx
        jmp .loop

.add_space:
        pop rdx                          ; recover regs
        pop rbx
        pop rsi
        pop rdi
        pop rax

        pop r11
        pop rcx

        pop rbp

        ret

;=======================================================
;                 WORK WITH CHAR (%c)
;=======================================================
putchar:
        push rbp
        mov  rbp, rsp

        push rcx                        ; save regs
        push r11

        push rax
        push rdi
        push rsi
        push rbx
        push rdx

        mov bl, [rbp + 0x10]            ; curr symbol

        mov rdi, [buffer_pos]           ; curr position

        cmp rdi, BUFFER_SIZE
        jb .write_to_buffer

        call flush_buffer               ; flush buffer if it is full
        mov rdi, [buffer_pos]

.write_to_buffer:
        lea rax, [buffer]
        mov [rax + rdi], bl             ; Записать символ в буфер
        inc rdi
        mov [buffer_pos], rdi

        pop rdx                         ; recover regs
        pop rbx
        pop rsi
        pop rdi
        pop rax

        pop r11
        pop rcx
        pop rbp

        ret

;=======================================================
;                 CLEAR NUMBER BUFFER
;=======================================================
clear_num_buffer:
        push rcx
        mov  rcx, BUFFER_SIZE

        lea rdi, [num_buffer]
        xor rax, rax
        rep stosb                       ; num_buffer[i] = 0

        pop rcx

        ret

;=======================================================
;                   CONVER TO BASE
;       receives two numbers as input from stack
;    (the number itself and the base of the system)
;               writes it to the buffer
;=======================================================
convert_to_base:
        push rbp
        mov  rbp, rsp

        push rax                        ; save regs
        push rcx
        push r10
        push r11
        push r12
        push rdx

        call clear_num_buffer           ; clear buffer with number

        mov rax, [rbp + 0x10]           ; arg1 - number
        xor rcx, rcx
        xor r10, r10

.nextdigit:                             ; put reversed representation of the number in buffer
        mov rdx, rax

        push rbx                        ; save rbx

        mov rbx, [rbp + 0x18]           ; divide by 10
        xor rdx, rdx
        div rbx

        pop rbx                         ; recover rbx

        cmp rdx, 0
        je .put_digit

        xor r10, r10
        dec r10

.put_digit:
        cmp rdx, 10
        jae .digit_is_letter

        add rdx, '0'
        jmp .put_digit_end

.digit_is_letter:
        add rdx, 'A' - 10
        jmp .put_digit_end

.put_digit_end:
        mov BYTE [num_buffer + rcx], dl

.loop_end:
        inc r10
        inc rcx

        cmp rcx, BUFFER_SIZE
        jne .nextdigit

        cmp r10, BUFFER_SIZE
        jne .not_zero

        push '0'
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
        pop rdx                         ; recover regs
        pop r12
        pop r11
        pop r10
        pop rcx
        pop rax

        pop rbp

        ret

;=======================================================
;                   FLUSH THE BUFFER
;=======================================================
flush_buffer:
        push rbp
        mov rbp, rsp

        push rax                        ; save regs
        push rdi
        push rsi
        push rdx
        push rcx

        mov rcx, [buffer_pos]           ; curr position
        test rcx, rcx
        jz .end

        mov rax, 0x01                   ; sys_write
        mov rdi, 0x01                   ; stdout
        lea rsi, [buffer]
        mov rdx, rcx
        syscall

        mov QWORD [buffer_pos], 0       ; curr position = 0

.end:
        pop rcx                         ; recover regs
        pop rdx
        pop rsi
        pop rdi
        pop rax

        pop rbp

        ret

;=======================================================
;                     DATA SECTION
;=======================================================
section .data
        char_buffer: db 0x00
        BUFFER_SIZE equ 64
        num_buffer: times (BUFFER_SIZE) db 0x00
        buffer: times (BUFFER_SIZE) db 0x00
        buffer_pos: dq 0x00
