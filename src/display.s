.code16
.global _start
_start:
    mov $0xB800,    %ax
    mov %ax,        %es

    movb    $'X',   %es:0x00
    movb    $0x07,  %es:0x01
    jmp     .

.org 510
boot_flag:
    .word 0xAA55
