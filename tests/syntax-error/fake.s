.section .text
.global add
add:
    add x0, x0, x1
    return

.global sub
sub:
    sub x0, x0, x1
    ret

.global mul
mul:
    mul x0, x0, x1
    ret
