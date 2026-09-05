; expect: PASS
    mov     OUTPUT, INPUT
    cpi     OUTPUT, 0
    brpl    already_positive
    neg     OUTPUT
already_positive:
    jmp     done
