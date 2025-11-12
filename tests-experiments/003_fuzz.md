# 003 Fuzz Test: Randomized Testing for macOS Tahoe Window Implementation

Date: 2025-11-10  
Operator: Glow G2 (Stoic Aquarian cadence)

## Objective
Validate Window buffer operations, dimension handling, and memory safety under randomized inputs. Tests focus on logic that doesn't require GUI initialization, ensuring TigerStyle safety: no unexpected panics for valid data, deterministic behavior for buffer operations, and alignment with static allocation constraints.

## Method
- Added a Zig test harness (`test "003 fuzz: ..."`) in `tests/003_fuzz.zig`.
- Custom LCG PRNG (SimpleRng, wrap-safe math) generates random inputs:
  - Random titles (1-256 characters)
  - Random pixel data (RGBA values)
  - Random pixel access patterns
  - Various buffer operation patterns
- Uses Arena allocator + `ArrayListUnmanaged` to minimize heap noise.
- Executed via `zig build test`.

## Test Categories

### 1. Window Buffer Operations with Random Data
- **Iterations**: 100 randomized configurations
- **Inputs**: Random titles (1-64 chars), random RGBA pixel data
- **Validations**:
  - Window dimensions match initialization (1024x768 static buffer)
  - Buffer size matches dimensions (width × height × 4)
  - Buffer is RGBA-aligned (length divisible by 4)
  - Random pixel access patterns stay within bounds
  - Pixel values are valid (0-255 range)

### 2. Window Dimension Edge Cases
- **Test Cases**: Various title lengths (1, 10, 50, 100, 200, 256 chars)
- **Validations**:
  - Dimensions are valid (positive, within 1024×768 bounds)
  - Buffer size matches dimensions
  - Buffer is RGBA-aligned
  - Title is preserved correctly
- **Random Iterations**: 50 random title lengths

### 3. Buffer Pattern Operations
- **Patterns Tested**:
  1. Solid color fill (green: 0xFF00FF00)
  2. Checkerboard pattern (32×32 pixel blocks)
  3. Random gradient (intensity based on X position)
  4. Random noise (1000 random pixel writes)
- **Validations**: All patterns write correctly to buffer without bounds violations

### 4. Buffer Bounds Safety
- **Test**: All valid pixel offsets within bounds
- **Method**: Iterate through all pixels (width × height), verify offset + 3 < buffer_size
- **Random Access**: 1000 random pixel accesses, verify bounds
- **Validations**: No out-of-bounds access, all pixel reads/writes safe

### 5. Title Handling
- **Test Cases**: Various title lengths (1, 10, 50, 100, 200, 256)
- **Random Iterations**: 50 random title lengths with random byte content
- **Validations**:
  - Title pointer and length preserved
  - Dimensions remain valid after initialization
  - No memory corruption

## Assertions Added

### Pointer Validation
- NULL checks for all Objective-C object pointers
- Alignment checks (8-byte alignment for Objective-C objects)
- Reasonable address checks (pointers > 0x1000)

### Buffer Validation
- Size validation (matches width × height × 4)
- RGBA alignment (length divisible by 4)
- Dimension matching (buffer size matches window dimensions)

### Dimension Validation
- Positive values (width > 0, height > 0)
- Within bounds (width ≤ 1024, height ≤ 768)
- Reasonable limits (max dimension checks)

### Selector Validation
- Not NULL before use
- Pointer validity checks

### Bounds Validation
- NSRect size non-negative
- Pixel offsets within buffer bounds
- Array access bounds checking

## Results
```
$ zig build test
... (pending execution)
```

## Notes
- Tests focus on buffer operations and memory safety, not GUI rendering
- Window initialization doesn't require GUI context (no `show()` call)
- Static buffer size (1024×768×4 = 3MB) is fixed, dimensions are not configurable
- All assertions use `std.debug.assert` for compile-time and runtime checks
- Fuzz test uses deterministic seeds for reproducible results
- Future extensions: 
  - Test actual GUI rendering (requires macOS GUI context)
  - Test window resize operations
  - Test multi-window scenarios
  - Test memory pressure scenarios
  - Test concurrent buffer access patterns


