; expect: WRONG
; never asks for the second value, so it adds the first to itself
    mov     r18, INPUT
    add     r18, INPUT
    mov     OUTPUT, r18
    jmp     done
resume:
