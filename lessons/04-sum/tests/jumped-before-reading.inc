; expect: WRONG
; asks for the second value before saving the first, losing it
    jmp     next_input
resume:
    mov     OUTPUT, INPUT
    jmp     done
