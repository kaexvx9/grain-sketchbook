//! Basin Kernel for Vantage VM
//! Why: RISC-V64 kernel with interactive REPL.
//! Grain Style: Explicit types, static allocation.

// === SBI Interface ===

fn sbi_putchar(c: u8) void {
    asm volatile ("ecall"
        :
        : [ext] "{a7}" (@as(u64, 0x01)),
          [arg0] "{a0}" (@as(u64, c)),
        : .{ .memory = true }
    );
}

fn sbi_getchar() u64 {
    var result: u64 = undefined;
    asm volatile ("ecall"
        : [ret] "={a0}" (result)
        : [ext] "{a7}" (@as(u64, 0x02)),
        : .{ .memory = true }
    );
    return result;
}

fn sbi_shutdown() noreturn {
    asm volatile ("ecall"
        :
        : [ext] "{a7}" (@as(u64, 0x53525354)),
          [func] "{a6}" (@as(u64, 0)),
          [arg0] "{a0}" (@as(u64, 0)),
          [arg1] "{a1}" (@as(u64, 0)),
        : .{ .memory = true }
    );
    unreachable;
}

// === Helpers ===

fn print_num(n: u64) void {
    if (n >= 10) print_num(n / 10);
    sbi_putchar(@truncate((n % 10) + '0'));
}

fn fib(n: u64) u64 {
    if (n <= 1) return n;
    var a: u64 = 0;
    var b: u64 = 1;
    var i: u64 = 2;
    while (i <= n) : (i += 1) {
        const tmp = a + b;
        a = b;
        b = tmp;
    }
    return b;
}

fn print_str(comptime s: []const u8) void {
    inline for (s) |c| sbi_putchar(c);
}

fn read_char() u64 {
    var c: u64 = 0xFFFFFFFFFFFFFFFF;
    while (c == 0xFFFFFFFFFFFFFFFF) c = sbi_getchar();
    return c;
}

// === Entry ===

export fn _start() callconv(.naked) noreturn {
    asm volatile ("lui sp, 0x80100\ncall basin_main");
    unreachable;
}

// === REPL ===

// Global to avoid optimizer issues
var g_cmd: u64 = 0;

// Variable storage (simple key-value store)
const MAX_VARS: u32 = 32;
const MAX_VAR_NAME: u32 = 16;

const Variable = struct {
    name: [MAX_VAR_NAME]u8,
    name_len: u32,
    value: i64,
    used: bool,
};

var variables: [MAX_VARS]Variable = [_]Variable{
    Variable{ .name = [_]u8{0} ** MAX_VAR_NAME, .name_len = 0, .value = 0, .used = false }
} ** MAX_VARS;

fn find_variable(name: []const u8) ?*Variable {
    for (&variables) |*v| {
        if (v.used and v.name_len == name.len) {
            var match: bool = true;
            for (0..name.len) |i| {
                if (v.name[i] != name[i]) {
                    match = false;
                    break;
                }
            }
            if (match) return v;
        }
    }
    return null;
}

fn create_variable(name: []const u8) ?*Variable {
    if (name.len == 0 or name.len > MAX_VAR_NAME) return null;
    
    // Check if already exists
    if (find_variable(name)) |existing| return existing;
    
    // Find unused slot
    for (&variables) |*v| {
        if (!v.used) {
            @memset(&v.name, 0);
            for (0..name.len) |i| {
                if (i < MAX_VAR_NAME) v.name[i] = name[i];
            }
            v.name_len = @intCast(name.len);
            v.value = 0;
            v.used = true;
            return v;
        }
    }
    return null; // No free slots
}

fn parse_identifier(s: []const u8, pos: *u64) ?[]const u8 {
    const start = pos.*;
    if (start >= s.len) return null;
    
    // Must start with letter or underscore
    const first = s[start];
    if ((first < 'a' or first > 'z') and (first < 'A' or first > 'Z') and first != '_') {
        return null;
    }
    
    pos.* += 1;
    while (pos.* < s.len) {
        const c = s[pos.*];
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or 
            (c >= '0' and c <= '9') or c == '_') {
            pos.* += 1;
        } else {
            break;
        }
    }
    
    return s[start..pos.*];
}

fn do_help() void {
    print_str("h:help f:fib e:expr v:vars c:clear q:quit\n");
    print_str("  expr: 2+3*4 or x=5 or x*2\n");
    print_str("  vars: list all variables\n");
    print_str("  clear: clear all variables\n");
}

fn do_fib(n: *u64) void {
    print_str("fib(");
    print_num(n.*);
    print_str(")=");
    print_num(fib(n.*));
    sbi_putchar('\n');
    n.* += 1;
    if (n.* > 20) n.* = 0;
}

fn do_quit() noreturn {
    print_str("Goodbye!\n");
    sbi_shutdown();
}

fn do_list_vars() void {
    var found: bool = false;
    for (&variables) |*v| {
        if (v.used) {
            found = true;
            // Print variable name
            for (0..v.name_len) |i| {
                sbi_putchar(v.name[i]);
            }
            print_str(" = ");
            // Print value
            if (v.value < 0) {
                sbi_putchar('-');
                print_num(@intCast(-v.value));
            } else {
                print_num(@intCast(v.value));
            }
            sbi_putchar('\n');
        }
    }
    if (!found) {
        print_str("No variables defined\n");
    }
}

fn do_clear_vars() void {
    for (&variables) |*v| {
        v.used = false;
        v.name_len = 0;
        v.value = 0;
        @memset(&v.name, 0);
    }
    print_str("All variables cleared\n");
}

// Simple expression evaluator (supports +, -, *, /, parentheses)
fn parse_number(s: []const u8, pos: *u64) ?i64 {
    var val: i64 = 0;
    const start: u64 = pos.*;
    var negative: bool = false;
    
    if (pos.* < s.len and s[pos.*] == '-') {
        negative = true;
        pos.* += 1;
    }
    
    if (pos.* >= s.len or s[pos.*] < '0' or s[pos.*] > '9') {
        pos.* = start;
        return null;
    }
    
    while (pos.* < s.len and s[pos.*] >= '0' and s[pos.*] <= '9') {
        val = val * 10 + (s[pos.*] - '0');
        pos.* += 1;
    }
    
    return if (negative) -val else val;
}

fn skip_whitespace(s: []const u8, pos: *u64) void {
    while (pos.* < s.len and (s[pos.*] == ' ' or s[pos.*] == '\t')) {
        pos.* += 1;
    }
}

fn eval_expr(s: []const u8, pos: *u64) ?i64 {
    skip_whitespace(s, pos);
    
    var result: ?i64 = null;
    
    // Handle unary minus
    if (pos.* < s.len and s[pos.*] == '-') {
        pos.* += 1;
        if (eval_expr(s, pos)) |val| {
            result = -val;
        } else {
            return null;
        }
    } else if (pos.* < s.len and s[pos.*] == '(') {
        // Parentheses
        pos.* += 1;
        result = eval_expr(s, pos);
        skip_whitespace(s, pos);
        if (pos.* >= s.len or s[pos.*] != ')') {
            return null;
        }
        pos.* += 1;
    } else {
        // Try identifier (variable) first
        const saved_pos = pos.*;
        if (parse_identifier(s, pos)) |ident| {
            if (find_variable(ident)) |v| {
                result = v.value;
            } else {
                // Not a variable, restore position and try number
                pos.* = saved_pos;
                result = parse_number(s, pos);
            }
        } else {
            // Number
            result = parse_number(s, pos);
        }
    }
    
    if (result == null) return null;
    var res = result.?;
    
    skip_whitespace(s, pos);
    
    // Handle operators (left-associative)
    while (pos.* < s.len) {
        const op = s[pos.*];
        if (op != '+' and op != '-' and op != '*' and op != '/') {
            break;
        }
        pos.* += 1;
        skip_whitespace(s, pos);
        
        var rhs: ?i64 = null;
        
        // Handle unary minus for RHS
        if (pos.* < s.len and s[pos.*] == '-') {
            pos.* += 1;
            if (eval_expr(s, pos)) |val| {
                rhs = -val;
            } else {
                return null;
            }
        } else if (pos.* < s.len and s[pos.*] == '(') {
            pos.* += 1;
            rhs = eval_expr(s, pos);
            skip_whitespace(s, pos);
            if (pos.* >= s.len or s[pos.*] != ')') {
                return null;
            }
            pos.* += 1;
        } else {
            rhs = parse_number(s, pos);
        }
        
        if (rhs == null) return null;
        
        // Apply operator (respect precedence: * and / before + and -)
        if (op == '*' or op == '/') {
            if (op == '*') {
                res *= rhs.?;
            } else {
                if (rhs.? == 0) {
                    print_str("Error: division by zero\n");
                    return null;
                }
                res = @divTrunc(res, rhs.?);
            }
        } else {
            // For + and -, we need to handle precedence correctly
            // This is a simplified version - full parser would need proper precedence
            if (op == '+') {
                res += rhs.?;
            } else {
                res -= rhs.?;
            }
        }
        
        skip_whitespace(s, pos);
    }
    
    return res;
}

fn do_expr() void {
    print_str("Enter expression or assignment (e.g., 2+3*4 or x=5): ");
    
    // Simple input buffer (max 64 chars)
    var input_buf: [64]u8 = undefined;
    var input_len: u64 = 0;
    
    // Read until newline
    while (input_len < 63) {
        const c = read_char();
        if (c == '\n' or c == '\r') break;
        if (c >= 32 and c <= 126) { // Printable ASCII
            sbi_putchar(@truncate(c));
            input_buf[input_len] = @truncate(c);
            input_len += 1;
        }
    }
    sbi_putchar('\n');
    
    if (input_len == 0) {
        print_str("Error: empty expression\n");
        return;
    }
    
    // Check for assignment (var = value)
    var pos: u64 = 0;
    skip_whitespace(input_buf[0..input_len], &pos);
    
    if (parse_identifier(input_buf[0..input_len], &pos)) |var_name| {
        skip_whitespace(input_buf[0..input_len], &pos);
        
        // Check for '=' assignment
        if (pos < input_len and input_buf[pos] == '=') {
            pos += 1;
            skip_whitespace(input_buf[0..input_len], &pos);
            
            // Evaluate right-hand side
            if (eval_expr(input_buf[0..input_len], &pos)) |value| {
                skip_whitespace(input_buf[0..input_len], &pos);
                if (pos < input_len) {
                    print_str("Error: invalid assignment\n");
                    return;
                }
                
                // Create or update variable
                if (create_variable(var_name)) |v| {
                    v.value = value;
                    // Print variable name character by character
                    for (var_name) |c| {
                        sbi_putchar(c);
                    }
                    print_str(" = ");
                    if (value < 0) {
                        sbi_putchar('-');
                        print_num(@intCast(-value));
                    } else {
                        print_num(@intCast(value));
                    }
                    sbi_putchar('\n');
                } else {
                    print_str("Error: too many variables or invalid name\n");
                }
            } else {
                print_str("Error: invalid expression\n");
            }
            return;
        } else {
            // Not an assignment, restore position and evaluate as expression
            pos = 0;
        }
    }
    
    // Evaluate as expression
    pos = 0;
    if (eval_expr(input_buf[0..input_len], &pos)) |result| {
        // Check if we consumed entire input
        skip_whitespace(input_buf[0..input_len], &pos);
        if (pos < input_len) {
            print_str("Error: invalid expression\n");
            return;
        }
        
        print_str("= ");
        if (result < 0) {
            sbi_putchar('-');
            print_num(@intCast(-result));
        } else {
            print_num(@intCast(result));
        }
        sbi_putchar('\n');
    } else {
        print_str("Error: invalid expression\n");
    }
}

export fn basin_main() callconv(.c) noreturn {
    print_str("Basin Kernel v0.4\n");
    print_str("Commands: h=help f=fib e=expr q=quit\n");
    print_str("  expr supports: +, -, *, /, (), variables (x=5, x*2)\n");

    var fib_n: u64 = 0;

    while (true) {
        print_str("> ");
        g_cmd = read_char();
        sbi_putchar(@truncate(g_cmd));
        sbi_putchar('\n');

        // Command dispatch
        if (g_cmd == 104) { // 'h'
            do_help();
        } else if (g_cmd == 102) { // 'f'
            do_fib(&fib_n);
        } else if (g_cmd == 101) { // 'e'
            do_expr();
        } else if (g_cmd == 113) { // 'q'
            do_quit();
        } else {
            print_str("OK\n");
        }
    }
}
