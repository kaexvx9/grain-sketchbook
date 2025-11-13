#include <objc/runtime.h>
#include <objc/message.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <CoreGraphics/CoreGraphics.h>

// BOOL type for Objective-C (typically signed char, but we'll use bool for compatibility).
#ifndef BOOL
#define BOOL bool
#endif

#ifndef YES
#define YES true
#endif

#ifndef NO
#define NO false
#endif

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

// Forward declarations for Zig event routing functions.
// These will be implemented in Zig to call the event handler.
void routeMouseEvent(uintptr_t window_ptr, uint32_t kind, uint32_t button, double x, double y, uint32_t modifiers);
void routeKeyboardEvent(uintptr_t window_ptr, uint32_t kind, uint32_t key_code, uint32_t character, uint32_t modifiers);
void routeFocusEvent(uintptr_t window_ptr, uint32_t kind);
void routeTickCallback(uintptr_t window_ptr);
void routeWindowDidResize(uintptr_t window_ptr, double new_width, double new_height);

// C function wrapper for windowDidResize: delegate method.
// This will be added to TahoeWindowDelegate class using class_addMethod.
// Signature: void windowDidResize:(id self, SEL _cmd, NSNotification* notification)
static void windowDidResizeImpl(id self, SEL _cmd, id notification) {
    (void)_cmd; // Unused parameter
    
    if (self == NULL || notification == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] NULL self or notification\n");
        fflush(stderr);
        return;
    }
    
    // Extract window_ptr from associated object.
    id window_ptr_obj = objc_getAssociatedObject(self, "windowPtr");
    if (window_ptr_obj == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] window_ptr not found in associated objects\n");
        fflush(stderr);
        return;
    }
    
    uintptr_t window_ptr = (uintptr_t)window_ptr_obj;
    if (window_ptr == 0) {
        fprintf(stderr, "[windowDidResizeImpl] window_ptr is 0\n");
        fflush(stderr);
        return;
    }
    
    // Extract NSWindow from notification's object.
    SEL objectSel = sel_registerName("object");
    if (objectSel == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] object selector not found\n");
        fflush(stderr);
        return;
    }
    
    id ns_window = ((id (*)(id, SEL))objc_msgSend)(notification, objectSel);
    if (ns_window == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] NSWindow from notification is NULL\n");
        fflush(stderr);
        return;
    }
    
    // Get window frame to extract new size.
    SEL frameSel = sel_registerName("frame");
    if (frameSel == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] frame selector not found\n");
        fflush(stderr);
        return;
    }
    
    NSRect frame = ((NSRect (*)(id, SEL))objc_msgSend)(ns_window, frameSel);
    
    // Extract content view frame (actual drawable area).
    SEL contentViewSel = sel_registerName("contentView");
    if (contentViewSel == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] contentView selector not found\n");
        fflush(stderr);
        return;
    }
    
    id content_view = ((id (*)(id, SEL))objc_msgSend)(ns_window, contentViewSel);
    if (content_view == NULL) {
        fprintf(stderr, "[windowDidResizeImpl] contentView is NULL\n");
        fflush(stderr);
        return;
    }
    
    NSRect content_frame = ((NSRect (*)(id, SEL))objc_msgSend)(content_view, frameSel);
    
    // Call Zig routeWindowDidResize function with new dimensions.
    routeWindowDidResize(window_ptr, content_frame.size.width, content_frame.size.height);
}

// Create window delegate instance using runtime API.
// Creates TahoeWindowDelegate class dynamically and returns an instance.
id createWindowDelegate(uintptr_t window_ptr) {
    if (window_ptr == 0) {
        fprintf(stderr, "[createWindowDelegate] NULL window_ptr\n");
        fflush(stderr);
        return NULL;
    }
    
    // Check if class already exists (avoid creating duplicate classes).
    static const char* delegateClassName = "TahoeWindowDelegate";
    Class delegateClass = objc_getClass(delegateClassName);
    
    if (delegateClass == NULL) {
        // Create new class: TahoeWindowDelegate extends NSObject.
        Class NSObjectClass = objc_getClass("NSObject");
        if (NSObjectClass == NULL) {
            fprintf(stderr, "[createWindowDelegate] NSObject class not found\n");
            fflush(stderr);
            return NULL;
        }
        
        delegateClass = objc_allocateClassPair(NSObjectClass, delegateClassName, 0);
        if (delegateClass == NULL) {
            fprintf(stderr, "[createWindowDelegate] Failed to allocate delegate class\n");
            fflush(stderr);
            return NULL;
        }
        
        // Add windowDidResize: method to the class.
        SEL resizeSel = sel_registerName("windowDidResize:");
        if (resizeSel == NULL) {
            fprintf(stderr, "[createWindowDelegate] Failed to register windowDidResize: selector\n");
            fflush(stderr);
            return NULL;
        }
        
        // Method type encoding: "v@:@" means (void return, id self, SEL _cmd, id notification)
        const char* methodTypes = "v@:@";
        
        // Add method to class.
        BOOL methodAdded = class_addMethod(delegateClass, resizeSel, (IMP)windowDidResizeImpl, methodTypes);
        if (!methodAdded) {
            fprintf(stderr, "[createWindowDelegate] Failed to add windowDidResize: method\n");
            fflush(stderr);
            return NULL;
        }
        
        // Register the class.
        objc_registerClassPair(delegateClass);
        fprintf(stderr, "[createWindowDelegate] Created TahoeWindowDelegate class\n");
        fflush(stderr);
    }
    
    // Allocate instance of delegate class.
    SEL allocSel = sel_registerName("alloc");
    if (allocSel == NULL) {
        fprintf(stderr, "[createWindowDelegate] alloc selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id delegate = ((id (*)(Class, SEL))objc_msgSend)(delegateClass, allocSel);
    if (delegate == NULL) {
        fprintf(stderr, "[createWindowDelegate] Failed to allocate delegate\n");
        fflush(stderr);
        return NULL;
    }
    
    SEL initSel = sel_registerName("init");
    if (initSel == NULL) {
        fprintf(stderr, "[createWindowDelegate] init selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id initializedDelegate = ((id (*)(id, SEL))objc_msgSend)(delegate, initSel);
    if (initializedDelegate == NULL) {
        fprintf(stderr, "[createWindowDelegate] Failed to initialize delegate\n");
        fflush(stderr);
        return NULL;
    }
    
    // Store window_ptr as associated object on delegate.
    void* window_ptr_obj = (void*)(uintptr_t)window_ptr;
    objc_setAssociatedObject(initializedDelegate, "windowPtr", (id)window_ptr_obj, OBJC_ASSOCIATION_ASSIGN);
    
    fprintf(stderr, "[createWindowDelegate] Created window delegate instance at: %p\n", initializedDelegate);
    fflush(stderr);
    
    return initializedDelegate;
}

// C function wrapper for timer callback method.
// This will be added to TahoeTimerTarget class using class_addMethod.
// Signature: void tahoeTimerTick:(id self, SEL _cmd, NSTimer* timer)
static void tahoeTimerTickImpl(id self, SEL _cmd, id timer) {
    (void)_cmd; // Unused parameter
    
    if (self == NULL || timer == NULL) {
        fprintf(stderr, "[tahoeTimerTickImpl] NULL self or timer\n");
        fflush(stderr);
        return;
    }
    
    // Extract window_ptr from timer's userInfo (NSNumber).
    SEL userInfoSel = sel_registerName("userInfo");
    if (userInfoSel == NULL) {
        fprintf(stderr, "[tahoeTimerTickImpl] userInfo selector not found\n");
        fflush(stderr);
        return;
    }
    
    id userInfo = ((id (*)(id, SEL))objc_msgSend)(timer, userInfoSel);
    if (userInfo == NULL) {
        fprintf(stderr, "[tahoeTimerTickImpl] Timer userInfo is NULL\n");
        fflush(stderr);
        return;
    }
    
    // Extract unsigned long long value from NSNumber.
    SEL unsignedLongLongValueSel = sel_registerName("unsignedLongLongValue");
    if (unsignedLongLongValueSel == NULL) {
        fprintf(stderr, "[tahoeTimerTickImpl] unsignedLongLongValue selector not found\n");
        fflush(stderr);
        return;
    }
    
    unsigned long long window_ptr = ((unsigned long long (*)(id, SEL))objc_msgSend)(userInfo, unsignedLongLongValueSel);
    
    if (window_ptr == 0) {
        fprintf(stderr, "[tahoeTimerTickImpl] window_ptr is 0\n");
        fflush(stderr);
        return;
    }
    
    // Call Zig routeTickCallback function.
    routeTickCallback((uintptr_t)window_ptr);
}

// Create animation timer that calls tick callback at specified interval.
// Uses NSTimer scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:
id createAnimationTimer(uintptr_t window_ptr, double interval) {
    if (window_ptr == 0) {
        fprintf(stderr, "[createAnimationTimer] NULL window_ptr\n");
        fflush(stderr);
        return NULL;
    }
    
    if (interval <= 0.0 || interval > 1.0) {
        fprintf(stderr, "[createAnimationTimer] Invalid interval: %f (expected 0 < interval <= 1.0)\n", interval);
        fflush(stderr);
        return NULL;
    }
    
    // Create a custom class dynamically using runtime API to handle timer callbacks.
    // We'll create a class that has a method calling routeTickCallback.
    
    // Check if class already exists (avoid creating duplicate classes).
    static const char* timerTargetClassName = "TahoeTimerTarget";
    Class timerTargetClass = objc_getClass(timerTargetClassName);
    
    if (timerTargetClass == NULL) {
        // Create new class: TahoeTimerTarget extends NSObject.
        Class NSObjectClass = objc_getClass("NSObject");
        if (NSObjectClass == NULL) {
            fprintf(stderr, "[createAnimationTimer] NSObject class not found\n");
            fflush(stderr);
            return NULL;
        }
        
        timerTargetClass = objc_allocateClassPair(NSObjectClass, timerTargetClassName, 0);
        if (timerTargetClass == NULL) {
            fprintf(stderr, "[createAnimationTimer] Failed to allocate timer target class\n");
            fflush(stderr);
            return NULL;
        }
        
        // Add instance variable to store window_ptr.
        // Note: We'll use associated objects instead since adding ivars is complex.
        
        // Register the class.
        objc_registerClassPair(timerTargetClass);
        fprintf(stderr, "[createAnimationTimer] Created TahoeTimerTarget class\n");
        fflush(stderr);
    }
    
    // Allocate instance of timer target class.
    SEL allocSel = sel_registerName("alloc");
    if (allocSel == NULL) {
        fprintf(stderr, "[createAnimationTimer] alloc selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id timerTarget = ((id (*)(Class, SEL))objc_msgSend)(timerTargetClass, allocSel);
    if (timerTarget == NULL) {
        fprintf(stderr, "[createAnimationTimer] Failed to allocate timer target\n");
        fflush(stderr);
        return NULL;
    }
    
    SEL initSel = sel_registerName("init");
    if (initSel == NULL) {
        fprintf(stderr, "[createAnimationTimer] init selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id initializedTarget = ((id (*)(id, SEL))objc_msgSend)(timerTarget, initSel);
    if (initializedTarget == NULL) {
        fprintf(stderr, "[createAnimationTimer] Failed to initialize timer target\n");
        fflush(stderr);
        return NULL;
    }
    
    // Store window_ptr as associated object on target.
    void* window_ptr_obj = (void*)(uintptr_t)window_ptr;
    objc_setAssociatedObject(initializedTarget, "windowPtr", (id)window_ptr_obj, OBJC_ASSOCIATION_ASSIGN);
    
    // Create timer with userInfo containing window_ptr (wrapped in NSNumber).
    Class NSNumberClass = objc_getClass("NSNumber");
    if (NSNumberClass == NULL) {
        fprintf(stderr, "[createAnimationTimer] NSNumber class not found\n");
        fflush(stderr);
        return NULL;
    }
    
    SEL numberWithUnsignedLongLongSel = sel_registerName("numberWithUnsignedLongLong:");
    if (numberWithUnsignedLongLongSel == NULL) {
        fprintf(stderr, "[createAnimationTimer] numberWithUnsignedLongLong: selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    id userInfo = ((id (*)(Class, SEL, unsigned long long))objc_msgSend)(NSNumberClass, numberWithUnsignedLongLongSel, window_ptr);
    if (userInfo == NULL) {
        fprintf(stderr, "[createAnimationTimer] Failed to create NSNumber for userInfo\n");
        fflush(stderr);
        return NULL;
    }
    
    // Add tahoeTimerTick: method to the class if it doesn't exist.
    // We'll add it every time (class_addMethod returns NO if method already exists, which is fine).
    SEL tickSel = sel_registerName("tahoeTimerTick:");
    if (tickSel == NULL) {
        fprintf(stderr, "[createAnimationTimer] Failed to register tick selector\n");
        fflush(stderr);
        return NULL;
    }
    
    // Get method type encoding: "v@:@" means (void return, id self, SEL _cmd, id timer)
    const char* methodTypes = "v@:@";
    
    // Add method to class.
    BOOL methodAdded = class_addMethod(timerTargetClass, tickSel, (IMP)tahoeTimerTickImpl, methodTypes);
    if (!methodAdded) {
        // Method might already exist, which is fine - we'll use the existing one.
        fprintf(stderr, "[createAnimationTimer] Method tahoeTimerTick: already exists or failed to add (continuing)\n");
        fflush(stderr);
    } else {
        fprintf(stderr, "[createAnimationTimer] Added tahoeTimerTick: method to TahoeTimerTarget class\n");
        fflush(stderr);
    }
    
    // Create timer using scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:
    // Note: scheduledTimerWithTimeInterval:target:selector:userInfo:repeats: is a class method.
    SEL scheduledTimerSel = sel_registerName("scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:");
    if (scheduledTimerSel == NULL) {
        fprintf(stderr, "[createAnimationTimer] scheduledTimerWithTimeInterval:target:selector:userInfo:repeats: selector not found\n");
        fflush(stderr);
        return NULL;
    }
    
    // Call class method: [NSTimer scheduledTimerWithTimeInterval:interval target:initializedTarget selector:tickSel userInfo:userInfo repeats:YES]
    Class NSTimerClass = objc_getClass("NSTimer");
    if (NSTimerClass == NULL) {
        fprintf(stderr, "[createAnimationTimer] NSTimer class not found\n");
        fflush(stderr);
        return NULL;
    }
    
    // scheduledTimerWithTimeInterval:target:selector:userInfo:repeats: signature:
    // + (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo
    id timer = ((id (*)(Class, SEL, double, id, SEL, id, BOOL))objc_msgSend)(
        NSTimerClass,
        scheduledTimerSel,
        interval,
        initializedTarget,
        tickSel,
        userInfo,
        YES // repeats
    );
    
    if (timer == NULL) {
        fprintf(stderr, "[createAnimationTimer] Failed to create NSTimer\n");
        fflush(stderr);
        return NULL;
    }
    
    fprintf(stderr, "[createAnimationTimer] Created NSTimer successfully at: %p\n", timer);
    fflush(stderr);
    
    return timer;
}
