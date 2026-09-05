; expect: PASS
; the long way round: com then inc is exactly what neg does
    mov     OUTPUT, INPUT
    cpi     OUTPUT, 0
    brpl    already_positive
    com     OUTPUT
    inc     OUTPUT
already_positive:
    jmp     done
