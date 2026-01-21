/* Basin Kernel Linker Script for RISC-V64 */
/* Why: Place kernel at 0x80000000 (standard RISC-V kernel address). */

OUTPUT_FORMAT(elf64-littleriscv)
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* RISC-V kernel typically loads at 2GB mark */
KERNEL_BASE = 0x80000000;

SECTIONS
{
    . = KERNEL_BASE;

    /* Code section */
    .text : AT(ADDR(.text) - KERNEL_BASE)
    {
        *(.text._start)
        *(.text .text.*)
    }

    /* Read-only data */
    .rodata : AT(ADDR(.rodata) - KERNEL_BASE)
    {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    }

    /* Writable data */
    .data : AT(ADDR(.data) - KERNEL_BASE)
    {
        *(.data .data.*)
        *(.sdata .sdata.*)
    }

    /* BSS (zero-initialized) */
    .bss : AT(ADDR(.bss) - KERNEL_BASE)
    {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        __bss_end = .;
    }

    /* Stack (at 1MB offset from base) */
    . = KERNEL_BASE + 0x100000;
    __stack_top = .;

    /* Discard unused sections */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.riscv.attributes)
    }
}
