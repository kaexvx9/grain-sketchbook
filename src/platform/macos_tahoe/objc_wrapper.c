#include <objc/runtime.h>
#include <objc/message.h>
#include <stdint.h>
#include <stdio.h>
#include <CoreGraphics/CoreGraphics.h>

// Forward declaration for NSSize (AppKit type).
typedef struct {
    double width;
    double height;
} NSSize;

// C wrapper for objc_msgSend to ensure proper calling convention on arm64.
// Why: objc_msgSend uses a special calling convention on arm64 that might
// not be handled correctly when called directly from Zig.
// Note: receiver can be a Class or id (they're compatible in Objective-C runtime).
id objc_msgSend_wrapper_string(void* receiver, SEL selector, const char* utf8_string) {
    // Assert: all parameters must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_wrapper_string] NULL receiver\n");
        fflush(stderr);
        return NULL;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_wrapper_string] NULL selector\n");
        fflush(stderr);
        return NULL;
    }
    if (utf8_string == NULL) {
        fprintf(stderr, "[objc_wrapper_string] NULL utf8_string\n");
        fflush(stderr);
        return NULL;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_string] Invalid receiver address: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    if (receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_wrapper_string] Receiver not aligned: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    // Assert: utf8_string must be null-terminated (check first 256 bytes).
    // Note: We can't check the full string without knowing its length, but we can verify
    // it's not obviously corrupted by checking it's in valid memory range.
    uintptr_t string_addr = (uintptr_t)utf8_string;
    if (string_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_string] Invalid string address: %p\n", utf8_string);
        fflush(stderr);
        return NULL;
    }
    
    id receiver_id = (id)receiver;
    return ((id (*)(id, SEL, const char*))objc_msgSend)(receiver_id, selector, utf8_string);
}

id objc_msgSend_wrapper(void* receiver, SEL selector) {
    // Assert: receiver and selector must be valid.
    // Note: We return NULL instead of crashing to let Zig handle the error.
    if (receiver == NULL) {
        // This should have been caught by Zig assertions, but check anyway.
        return NULL;
    }
    if (selector == NULL) {
        // This should have been caught by Zig assertions, but check anyway.
        return NULL;
    }
    
    // Additional validation: check if receiver looks like a valid pointer.
    // Objective-C objects/classes are typically aligned and in reasonable memory ranges.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000) {
        // Suspiciously small address - likely invalid.
        return NULL;
    }
    if (receiver_addr % 8 != 0) {
        // Not properly aligned - likely invalid.
        return NULL;
    }
    
    // Cast receiver to id (works for both Class and object pointers).
    // On arm64, objc_msgSend handles the dispatch internally.
    id receiver_id = (id)receiver;
    
    // Additional check: verify receiver looks like a valid Objective-C object/class.
    // For Objective-C objects/classes, the first field is the ISA pointer.
    // On arm64, we can check if the ISA pointer is valid.
    // Note: This is a heuristic check - if the ISA is NULL or invalid,
    // the object/class structure is likely corrupted or not initialized.
    // 
    // Debug: Print receiver and ISA pointer values to diagnose the issue.
    // Note: We dereference the receiver pointer to get the ISA pointer.
    // On arm64, the ISA pointer is the first 8 bytes of the class structure.
    void* isa_ptr = *(void**)receiver_id;
    
    // Debug output: print receiver and ISA pointer addresses.
    // This helps us understand why the ISA pointer check is failing.
    // Note: We use fprintf to stderr to avoid buffering issues.
    fprintf(stderr, "[objc_wrapper] receiver: %p, ISA pointer: %p\n", receiver_id, isa_ptr);
    fflush(stderr);
    
    if (isa_ptr == NULL) {
        // ISA pointer is NULL - this is invalid for Objective-C objects/classes.
        // This suggests the class isn't properly initialized or loaded.
        // Return NULL instead of crashing - let Zig handle the error.
        // Note: The Objective-C test shows the ISA pointer should be valid (0x2071dd940),
        // so if we're getting NULL here, there might be a memory access issue.
        return NULL;
    }
    uintptr_t isa_addr = (uintptr_t)isa_ptr;
    if (isa_addr < 0x1000) {
        // ISA pointer is suspiciously small - likely invalid.
        // This suggests the class structure is corrupted.
        return NULL;
    }
    if (isa_addr % 8 != 0) {
        // ISA pointer is not aligned - likely invalid.
        // Objective-C ISA pointers should be 8-byte aligned on arm64.
        return NULL;
    }
    // Additional check: verify ISA pointer looks reasonable.
    // ISA pointers typically point to class structures in a specific memory range.
    // If it's in a suspicious range, it might be invalid.
    // Note: On macOS, valid pointers are typically in user space (< 0x7fffffffffff).
    if (isa_addr > 0x7fffffffffff) {
        // ISA pointer is in kernel space or invalid range - likely invalid.
        return NULL;
    }
    
    // Call objc_msgSend with proper casting.
    // Note: The function pointer cast ensures the correct signature.
    // If this segfaults, it means there's a deeper issue with the Objective-C runtime
    // initialization or the class structure is invalid despite our checks.
    return ((id (*)(id, SEL))objc_msgSend)(receiver_id, selector);
}

// NSRect struct definition to match Cocoa
typedef struct {
    struct { double x, y; } origin;
    struct { double width, height; } size;
} NSRect;

id objc_msgSend_wrapper_rect(void* receiver, SEL selector, void* rect_ptr) {
    // Assert: all parameters must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_wrapper_rect] NULL receiver\n");
        fflush(stderr);
        return NULL;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_wrapper_rect] NULL selector\n");
        fflush(stderr);
        return NULL;
    }
    if (rect_ptr == NULL) {
        fprintf(stderr, "[objc_wrapper_rect] NULL rect_ptr\n");
        fflush(stderr);
        return NULL;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_rect] Invalid receiver address: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    if (receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_wrapper_rect] Receiver not aligned: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    // Assert: rect_ptr must be valid and aligned.
    uintptr_t rect_addr = (uintptr_t)rect_ptr;
    if (rect_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_rect] Invalid rect_ptr address: %p\n", rect_ptr);
        fflush(stderr);
        return NULL;
    }
    if (rect_addr % 8 != 0) {
        fprintf(stderr, "[objc_wrapper_rect] rect_ptr not aligned: %p\n", rect_ptr);
        fflush(stderr);
        return NULL;
    }
    
    // Note: For uninitialized objects (like after alloc), the ISA pointer might not be valid yet.
    // We'll let objc_msgSend handle the validation - it will segfault if the object is truly invalid.
    id receiver_id = (id)receiver;
    
    // NSRect is passed by value on arm64, not by pointer.
    // Copy the struct from the pointer (static copy, no allocation).
    NSRect rect = *(NSRect*)rect_ptr;
    
    // Assert: rect values must be reasonable.
    if (rect.size.width < 0 || rect.size.height < 0) {
        fprintf(stderr, "[objc_wrapper_rect] Invalid rect dimensions: w=%f, h=%f\n", rect.size.width, rect.size.height);
        fflush(stderr);
        return NULL;
    }
    if (rect.size.width > 16384 || rect.size.height > 16384) {
        fprintf(stderr, "[objc_wrapper_rect] Rect dimensions too large: w=%f, h=%f\n", rect.size.width, rect.size.height);
        fflush(stderr);
        return NULL;
    }
    
    // Call objc_msgSend - it will handle object validation internally.
    return ((id (*)(id, SEL, NSRect))objc_msgSend)(receiver_id, selector, rect);
}

id objc_msgSend_wrapper_4(void* receiver, SEL selector, void* rect_ptr, unsigned long arg2, unsigned long arg3, _Bool arg4) {
    // Assert: all parameters must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_wrapper_4] NULL receiver\n");
        fflush(stderr);
        return NULL;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_wrapper_4] NULL selector\n");
        fflush(stderr);
        return NULL;
    }
    if (rect_ptr == NULL) {
        fprintf(stderr, "[objc_wrapper_4] NULL rect_ptr\n");
        fflush(stderr);
        return NULL;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_4] Invalid receiver address: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    if (receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_wrapper_4] Receiver not aligned: %p\n", receiver);
        fflush(stderr);
        return NULL;
    }
    // Assert: rect_ptr must be valid and aligned.
    uintptr_t rect_addr = (uintptr_t)rect_ptr;
    if (rect_addr < 0x1000) {
        fprintf(stderr, "[objc_wrapper_4] Invalid rect_ptr address: %p\n", rect_ptr);
        fflush(stderr);
        return NULL;
    }
    if (rect_addr % 8 != 0) {
        fprintf(stderr, "[objc_wrapper_4] rect_ptr not aligned: %p\n", rect_ptr);
        fflush(stderr);
        return NULL;
    }
    // Assert: arg2 and arg3 must be reasonable (styleMask and backingType).
    if (arg2 > 0xFFFFFFFF) {
        fprintf(stderr, "[objc_wrapper_4] arg2 (styleMask) too large: %lu\n", arg2);
        fflush(stderr);
        return NULL;
    }
    if (arg3 > 0xFFFFFFFF) {
        fprintf(stderr, "[objc_wrapper_4] arg3 (backingType) too large: %lu\n", arg3);
        fflush(stderr);
        return NULL;
    }
    
    // Note: For uninitialized objects (like after alloc), the ISA pointer might not be valid yet.
    // We'll let objc_msgSend handle the validation - it will segfault if the object is truly invalid.
    id receiver_id = (id)receiver;
    
    // NSRect is passed by value on arm64, not by pointer.
    // Copy the struct from the pointer (static copy, no allocation).
    NSRect rect = *(NSRect*)rect_ptr;
    
    // Assert: rect values must be reasonable.
    if (rect.size.width < 0 || rect.size.height < 0) {
        fprintf(stderr, "[objc_wrapper_4] Invalid rect dimensions: w=%f, h=%f\n", rect.size.width, rect.size.height);
        fflush(stderr);
        return NULL;
    }
    if (rect.size.width > 16384 || rect.size.height > 16384) {
        fprintf(stderr, "[objc_wrapper_4] Rect dimensions too large: w=%f, h=%f\n", rect.size.width, rect.size.height);
        fflush(stderr);
        return NULL;
    }
    
    // Call objc_msgSend - it will handle object validation internally.
    return ((id (*)(id, SEL, NSRect, unsigned long, unsigned long, _Bool))objc_msgSend)(receiver_id, selector, rect, arg2, arg3, arg4);
}

void objc_msgSend_void_1(void* receiver, SEL selector, void* arg1) {
    // Assert: receiver and selector must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_msgSend_void_1] NULL receiver\n");
        fflush(stderr);
        return;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_msgSend_void_1] NULL selector\n");
        fflush(stderr);
        return;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000 || receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_msgSend_void_1] Invalid receiver: %p\n", receiver);
        fflush(stderr);
        return;
    }
    // Assert: arg1 must be valid if provided (can be NULL for some methods).
    if (arg1 != NULL) {
        uintptr_t arg1_addr = (uintptr_t)arg1;
        if (arg1_addr < 0x1000 || arg1_addr % 8 != 0) {
            fprintf(stderr, "[objc_msgSend_void_1] Invalid arg1: %p\n", arg1);
            fflush(stderr);
            return;
        }
    }
    id receiver_id = (id)receiver;
    id arg1_id = (id)arg1;
    ((void (*)(id, SEL, id))objc_msgSend)(receiver_id, selector, arg1_id);
}

void objc_msgSend_void_0(void* receiver, SEL selector) {
    // Assert: receiver and selector must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_msgSend_void_0] NULL receiver\n");
        fflush(stderr);
        return;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_msgSend_void_0] NULL selector\n");
        fflush(stderr);
        return;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000 || receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_msgSend_void_0] Invalid receiver: %p\n", receiver);
        fflush(stderr);
        return;
    }
    id receiver_id = (id)receiver;
    ((void (*)(id, SEL))objc_msgSend)(receiver_id, selector);
}

void objc_msgSend_void_1_bool(void* receiver, SEL selector, _Bool arg1) {
    // Assert: receiver and selector must be valid.
    if (receiver == NULL) {
        fprintf(stderr, "[objc_msgSend_void_1_bool] NULL receiver\n");
        fflush(stderr);
        return;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_msgSend_void_1_bool] NULL selector\n");
        fflush(stderr);
        return;
    }
    // Assert: receiver address must be reasonable and aligned.
    uintptr_t receiver_addr = (uintptr_t)receiver;
    if (receiver_addr < 0x1000 || receiver_addr % 8 != 0) {
        fprintf(stderr, "[objc_msgSend_void_1_bool] Invalid receiver: %p\n", receiver);
        fflush(stderr);
        return;
    }
    id receiver_id = (id)receiver;
    ((void (*)(id, SEL, _Bool))objc_msgSend)(receiver_id, selector, arg1);
}

// Helper function to create NSImage from CGImage.
// Why: NSImage doesn't have imageWithCGImage:size: class method.
// Instead, we create NSBitmapImageRep from CGImage, then create NSImage from that.
id createNSImageFromCGImage(void* cgImage, double width, double height) {
    if (cgImage == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NULL cgImage\n");
        fflush(stderr);
        return NULL;
    }
    
    CGImageRef cgImageRef = (CGImageRef)cgImage;
    
    // Step 1: Create NSBitmapImageRep from CGImage.
    Class NSBitmapImageRepClass = objc_getClass("NSBitmapImageRep");
    if (NSBitmapImageRepClass == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSBitmapImageRep class not found\n");
        fflush(stderr);
        return NULL;
    }
    
    SEL allocSel = sel_registerName("alloc");
    if (allocSel == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] alloc selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id bitmapRep = ((id (*)(Class, SEL))objc_msgSend)(NSBitmapImageRepClass, allocSel);
    if (bitmapRep == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSBitmapImageRep alloc returned NULL\n");
        fflush(stderr);
        return NULL;
    }
    
    SEL initWithCGImageSel = sel_registerName("initWithCGImage:");
    if (initWithCGImageSel == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] initWithCGImage: selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id initializedBitmapRep = ((id (*)(id, SEL, CGImageRef))objc_msgSend)(bitmapRep, initWithCGImageSel, cgImageRef);
    if (initializedBitmapRep == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSBitmapImageRep initWithCGImage: returned NULL\n");
        fflush(stderr);
        return NULL;
    }
    
    // Step 2: Create NSImage with size.
    Class NSImageClass = objc_getClass("NSImage");
    if (NSImageClass == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSImage class not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id nsImage = ((id (*)(Class, SEL))objc_msgSend)(NSImageClass, allocSel);
    if (nsImage == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSImage alloc returned NULL\n");
        fflush(stderr);
        return NULL;
    }
    
    NSSize size = {width, height};
    SEL initWithSizeSel = sel_registerName("initWithSize:");
    if (initWithSizeSel == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] initWithSize: selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id initializedImage = ((id (*)(id, SEL, NSSize))objc_msgSend)(nsImage, initWithSizeSel, size);
    if (initializedImage == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] NSImage initWithSize: returned NULL\n");
        fflush(stderr);
        return NULL;
    }
    
    // Step 3: Add bitmap representation to NSImage.
    SEL addRepresentationSel = sel_registerName("addRepresentation:");
    if (addRepresentationSel == NULL) {
        fprintf(stderr, "[createNSImageFromCGImage] addRepresentation: selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    ((void (*)(id, SEL, id))objc_msgSend)(initializedImage, addRepresentationSel, initializedBitmapRep);
    
    fprintf(stderr, "[createNSImageFromCGImage] Created NSImage at: %p\n", initializedImage);
    fflush(stderr);
    
    return initializedImage;
}

// Helper function to get NSRect return value from objc_msgSend.
// Why: Methods like bounds return NSRect by value (in registers on arm64), not as object pointers.
NSRect objc_msgSend_returns_NSRect(void* receiver, SEL selector) {
    if (receiver == NULL) {
        fprintf(stderr, "[objc_msgSend_returns_NSRect] NULL receiver\n");
        fflush(stderr);
        NSRect empty = {{0, 0}, {0, 0}};
        return empty;
    }
    if (selector == NULL) {
        fprintf(stderr, "[objc_msgSend_returns_NSRect] NULL selector\n");
        fflush(stderr);
        NSRect empty = {{0, 0}, {0, 0}};
        return empty;
    }
    
    id receiver_id = (id)receiver;
    // Call objc_msgSend with NSRect return type.
    // On arm64, structs are returned in registers.
    return ((NSRect (*)(id, SEL))objc_msgSend)(receiver_id, selector);
}
