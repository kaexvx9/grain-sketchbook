# Third-Party License Attributions

This file contains license attributions for third-party software used in the Rye compiler.

---

## Zig Compiler

**Repository**: https://codeberg.org/ziglang/zig  
**Tag**: 0.15.2  
**Commit**: e4cbd752c8c05f131051f8c873cff7823177d7d3  
**License**: MIT License  
**Copyright**: Copyright (c) 2015-2025 Zig contributors

Rye is a fork of Zig 0.15.2, adapted for:
- RISC-V freestanding codegen fixes
- Toroidal/garden type system
- Rye Style enforcement
- Chronological versioning
- Garden-allocation model

### MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## LLVM

**Repository**: https://github.com/llvm/llvm-project  
**License**: Apache License 2.0 with LLVM Exceptions  
**Copyright**: LLVM Project contributors

Rye uses LLVM as its code generation backend (inherited from Zig).

[Full LLVM license text with exceptions]

---

## Other Dependencies

[Add other dependencies as needed]
