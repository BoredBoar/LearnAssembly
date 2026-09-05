; expect: DARK
; correct total, never signalled
    mov     r18, INPUT
    jmp     next_input
resume:
    add     r18, INPUT
    mov     OUTPUT, r18
