.section .text.init
.global _start

_start:
    # Set up stack pointer (kernel will set this, but initialize for safety)
    # Stack will be set by kernel when process is spawned
    la sp, _stack_top
    
    # Call Zig main function
    call main
    
    # Exit if main returns (syscall exit)
    # Kernel will handle process cleanup
    j .

.section .bss
.align 4
.global _stack_bottom
.global _stack_top
_stack_bottom:
    .skip 4096 * 16 # 64KB stack for shell
_stack_top:
