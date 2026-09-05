; expect: WRONG
; fails at round 3, where the input is already positive
    mov     OUTPUT, INPUT
    neg     OUTPUT
    jmp     done
