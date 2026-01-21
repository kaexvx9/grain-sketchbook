// x86_64 Kernel Entry Point
// Why: First code executed after bootloader jumps to kernel.
// Grain Style: Minimal assembly, quick jump to Zig.

.section .text.boot
.global _start
.global kernel_stack_top

_start:
    // Disable interrupts
    cli

    // Set up kernel stack
    lea rsp, [rip + kernel_stack_top]

    // Clear RFLAGS
    push 0
    popfq

    // Clear BSS section
    lea rdi, [rip + __bss_start]
    lea rcx, [rip + __bss_end]
    sub rcx, rdi
    shr rcx, 3          // Divide by 8 (qwords)
    xor rax, rax
    rep stosq

    // Call Zig kernel main
    // RDI = boot_info pointer (passed from bootloader)
    call kernel_main_x86_64

    // If kernel returns, halt
.halt_loop:
    hlt
    jmp .halt_loop

.section .bss
.align 16
kernel_stack_bottom:
    .space 65536        // 64KB kernel stack
kernel_stack_top:

// BSS markers (filled by linker)
.section .bss
__bss_start:
__bss_end:
