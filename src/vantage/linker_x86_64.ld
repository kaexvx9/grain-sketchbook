/* Vantage VM Linker Script for x86_64 (Limine Boot Protocol)
 * Why: Define memory layout for Vantage VM higher-half kernel.
 * Grain Style: Explicit addresses, clear section organization.
 * 
 * Architecture: Vantage VM runs on x86_64 and emulates RISC-V64.
 * This linker script is for Vantage VM itself (x86_64), NOT for Basin kernel (RISC-V64).
 *
 * Memory Layout:
 *   0xffffffff80000000+ : Vantage VM kernel code and data (higher half)
 *   0xffff800000000000+ : HHDM (Higher Half Direct Map) for physmem
 *   0x0000000000000000  : User space (lower half)
 */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

/* Vantage VM entry point */
ENTRY(_start)

/* Program headers for Limine */
PHDRS
{
    limine_requests PT_LOAD FLAGS(6); /* RW */
    text            PT_LOAD FLAGS(5); /* RX */
    rodata          PT_LOAD FLAGS(4); /* R  */
    data            PT_LOAD FLAGS(6); /* RW */
}

SECTIONS
{
    /* Higher half kernel base address */
    . = 0xffffffff80000000;

    /* Limine requests section (must be first) */
    .limine_requests : {
        KEEP(*(.limine_requests_start))
        KEEP(*(.limine_requests))
        KEEP(*(.limine_requests_end))
    } :limine_requests

    /* Align to page boundary */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    /* Code section */
    .text : {
        *(.text .text.*)
    } :text

    /* Align to page boundary */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    /* Read-only data */
    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    /* Build ID (if present) */
    .note.gnu.build-id : {
        *(.note.gnu.build-id)
    } :rodata

    /* Align to page boundary */
    . = ALIGN(CONSTANT(MAXPAGESIZE));

    /* Data section */
    .data : {
        *(.data .data.*)
    } :data

    /* BSS section (must be last in :data) */
    .bss : {
        *(COMMON)
        *(.bss .bss.*)
    } :data

    /* Kernel end marker */
    _kernel_end = .;

    /* Discard unnecessary sections */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
        *(.comment)
    }
}
