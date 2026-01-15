OUTPUT_ARCH(riscv)
ENTRY(_start)
SECTIONS
{
    . = 0x80200000;
    .text : {
        *(.text.boot)
        *(.text*)
    }

    .rodata : {
        *(.srodata*)
        *(.rodata*)
    }

    .data : {
        *(.sdata*)
        *(.data*)
    }

    .bss : {
        *(.sbss*)
        *(.bss*)
        *(COMMON)
    }
}
