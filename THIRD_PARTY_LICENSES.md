# Third-Party License Attributions

This file contains license attributions for third-party software used in this project.

---

## ZON Format

**Repository**: https://github.com/ZON-Format/ZON  
**Location**: `grainstore/github/ZON-Format/ZON`  
**License**: MIT License  
**Copyright**: Copyright (c) 2025 ZON-FORMAT (Roni Bhakta)

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

## TigerBeetle

**Repository**: https://github.com/tigerbeetle/tigerbeetle  
**Usage**: Grain Style guide inspiration and adaptation  
**License**: Apache License 2.0  
**Copyright**: Copyright (c) 2021-2025 TigerBeetle

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

**Note**: Grain OS's Grain Style guide (`docs/grain_style.md`) is heavily inspired by and adapted from TigerBeetle's TIGER_STYLE.md. The core philosophy, safety rules, and many specific guidelines are adapted from TIGER_STYLE with modifications for Grain OS's specific context (graincards, grain_case naming, etc.). We are deeply grateful to the TigerBeetle team for sharing their wisdom.

---

## Clojure

**Repository**: https://github.com/clojure/clojure  
**Usage**: Philosophy inspiration ("Simple Made Easy", data-oriented design principles)  
**License**: Eclipse Public License 1.0  
**Copyright**: Copyright (c) Rich Hickey. All rights reserved.

THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC
LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM
CONSTITUTES RECIPIENT'S ACCEPTANCE OF THIS AGREEMENT.

1. DEFINITIONS

"Contribution" means:
a) in the case of the initial Contributor, the initial code and documentation
   distributed under this Agreement, and
b) in the case of each subsequent Contributor:
   i) changes to the Program, and
   ii) additions to the Program;

where such changes and/or additions to the Program originate from and are
distributed by that particular Contributor. A Contribution 'originates' from a
Contributor if it was added to the Program by such Contributor itself or anyone
acting on such Contributor's behalf. Contributions do not include additions to
the Program which: (i) are separate modules of software distributed in
conjunction with the Program under their own license agreement, and (ii) are not
derivative works of the Program.

**Note**: Rich Hickey's talks on simplicity, particularly "Simple Made Easy" (2011), have deeply
influenced Grain OS's approach to system design. The emphasis on simplicity over complexity,
on decoupling, on data-oriented design, and on distinguishing between "simple" (not intertwined)
and "easy" (familiar/near at hand) informs our architectural decisions. We choose Zig as our
implementation language because it embodies these principles: explicit over implicit, no hidden
control flow, no hidden memory allocations, composition over inheritance.

---

## Clojure

**Repository**: https://github.com/clojure/clojure  
**Usage**: Philosophy inspiration for simplicity-focused design  
**License**: Eclipse Public License 1.0  
**Copyright**: Copyright (c) Rich Hickey. All rights reserved.

THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC
LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM
CONSTITUTES RECIPIENT'S ACCEPTANCE OF THIS AGREEMENT.

The full Eclipse Public License 1.0 is available at:
https://opensource.org/licenses/EPL-1.0

**Note**: While Grain OS is written in Zig rather than Clojure, we draw inspiration from Rich Hickey's philosophy of simplicity, immutability, and data-oriented design. The Clojure community's emphasis on "simple made easy" and thoughtful API design has influenced our approach to systems programming. We appreciate Clojure's permissive licensing model that enables open collaboration.

---
