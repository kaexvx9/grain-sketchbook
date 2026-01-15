//! Grain OS IP Address Management: IPv4/IPv6 address parsing, validation, conversion.
//!
//! Why: Provide robust IP address utilities for network interface management.
//! Architecture: IPv4/IPv6 parsing, validation, string conversion, address utilities.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const network_stack = @import("network_stack.zig");

// Bounded: Max IPv4 address string length ("255.255.255.255").
pub const MAX_IPV4_STRING_LEN: u32 = 15;

// Bounded: Max IPv6 address string length (compressed format).
pub const MAX_IPV6_STRING_LEN: u32 = 39;

// Bounded: Max IP address string length (IPv6 is longer).
pub const MAX_IP_STRING_LEN: u32 = MAX_IPV6_STRING_LEN;

// Parse IPv4 address from string (e.g., "192.168.1.1").
pub fn parse_ipv4(ip_str: []const u8) ?[4]u8 {
    std.debug.assert(ip_str.len > 0);
    std.debug.assert(ip_str.len <= MAX_IPV4_STRING_LEN);
    if (ip_str.len == 0 or ip_str.len > MAX_IPV4_STRING_LEN) {
        return null;
    }
    var addr: [4]u8 = undefined;
    var octet_idx: u32 = 0;
    var current_octet: u32 = 0;
    var i: u32 = 0;
    while (i < ip_str.len) : (i += 1) {
        const c = ip_str[i];
        if (c == '.') {
            if (octet_idx >= 4) {
                return null;
            }
            if (current_octet > 255) {
                return null;
            }
            addr[octet_idx] = @intCast(current_octet);
            octet_idx += 1;
            current_octet = 0;
        } else if (c >= '0' and c <= '9') {
            current_octet = current_octet * 10 + (c - '0');
            if (current_octet > 255) {
                return null;
            }
        } else {
            return null;
        }
    }
    if (octet_idx != 3) {
        return null;
    }
    if (current_octet > 255) {
        return null;
    }
    addr[octet_idx] = @intCast(current_octet);
    std.debug.assert(octet_idx == 3);
    std.debug.assert(addr[0] <= 255);
    return addr;
}

// Validate IPv4 address format.
pub fn is_valid_ipv4(ip_str: []const u8) bool {
    std.debug.assert(ip_str.len > 0);
    std.debug.assert(ip_str.len <= MAX_IPV4_STRING_LEN);
    return parse_ipv4(ip_str) != null;
}

// Format IPv4 address to string.
pub fn format_ipv4(addr: [4]u8, buf: []u8) ?u32 {
    std.debug.assert(buf.len >= MAX_IPV4_STRING_LEN);
    if (buf.len < MAX_IPV4_STRING_LEN) {
        return null;
    }
    var pos: u32 = 0;
    var i: u32 = 0;
    while (i < 4) : (i += 1) {
        if (i > 0) {
            buf[pos] = '.';
            pos += 1;
        }
        const octet = addr[i];
        if (octet >= 100) {
            buf[pos] = '0' + (octet / 100);
            pos += 1;
            buf[pos] = '0' + ((octet / 10) % 10);
            pos += 1;
            buf[pos] = '0' + (octet % 10);
            pos += 1;
        } else if (octet >= 10) {
            buf[pos] = '0' + (octet / 10);
            pos += 1;
            buf[pos] = '0' + (octet % 10);
            pos += 1;
        } else {
            buf[pos] = '0' + octet;
            pos += 1;
        }
    }
    std.debug.assert(pos <= MAX_IPV4_STRING_LEN);
    return pos;
}

// Parse IPv6 address from string (simplified, supports common formats).
pub fn parse_ipv6(ip_str: []const u8) ?[16]u8 {
    std.debug.assert(ip_str.len > 0);
    std.debug.assert(ip_str.len <= MAX_IPV6_STRING_LEN);
    if (ip_str.len == 0 or ip_str.len > MAX_IPV6_STRING_LEN) {
        return null;
    }
    var addr: [16]u8 = undefined;
    var i: u32 = 0;
    while (i < 16) : (i += 1) {
        addr[i] = 0;
    }
    var pos: u32 = 0;
    var group_idx: u32 = 0;
    var current_group: u32 = 0;
    var in_group = false;
    while (pos < ip_str.len and group_idx < 8) : (pos += 1) {
        const c = ip_str[pos];
        if (c == ':') {
            if (in_group) {
                if (current_group > 65535) {
                    return null;
                }
                const group_bytes = [2]u8{
                    @intCast((current_group >> 8) & 0xFF),
                    @intCast(current_group & 0xFF),
                };
                addr[group_idx * 2] = group_bytes[0];
                addr[group_idx * 2 + 1] = group_bytes[1];
                group_idx += 1;
                current_group = 0;
                in_group = false;
            }
        } else if ((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')) {
            in_group = true;
            const digit = if (c >= '0' and c <= '9') (c - '0') else (
                if (c >= 'a' and c <= 'f') (c - 'a' + 10) else (c - 'A' + 10)
            );
            current_group = current_group * 16 + digit;
            if (current_group > 65535) {
                return null;
            }
        } else {
            return null;
        }
    }
    if (in_group and group_idx < 8) {
        if (current_group > 65535) {
            return null;
        }
        const group_bytes = [2]u8{
            @intCast((current_group >> 8) & 0xFF),
            @intCast(current_group & 0xFF),
        };
        addr[group_idx * 2] = group_bytes[0];
        addr[group_idx * 2 + 1] = group_bytes[1];
        group_idx += 1;
    }
    if (group_idx != 8) {
        return null;
    }
    std.debug.assert(group_idx == 8);
    std.debug.assert(addr[0] <= 255);
    return addr;
}

// Validate IPv6 address format.
pub fn is_valid_ipv6(ip_str: []const u8) bool {
    std.debug.assert(ip_str.len > 0);
    std.debug.assert(ip_str.len <= MAX_IPV6_STRING_LEN);
    return parse_ipv6(ip_str) != null;
}

// Format IPv6 address to string (simplified, no compression).
pub fn format_ipv6(addr: [16]u8, buf: []u8) ?u32 {
    std.debug.assert(buf.len >= MAX_IPV6_STRING_LEN);
    if (buf.len < MAX_IPV6_STRING_LEN) {
        return null;
    }
    var pos: u32 = 0;
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        if (i > 0) {
            buf[pos] = ':';
            pos += 1;
        }
        const group = (@as(u16, addr[i * 2]) << 8) | addr[i * 2 + 1];
        const hex_digits = "0123456789abcdef";
        var shift: u32 = 12;
        var printed = false;
        while (shift > 0) : (shift -= 4) {
            const digit = (group >> shift) & 0xF;
            if (digit > 0 or printed) {
                buf[pos] = hex_digits[digit];
                pos += 1;
                printed = true;
            }
        }
        if (!printed) {
            buf[pos] = '0';
            pos += 1;
        }
    }
    std.debug.assert(pos <= MAX_IPV6_STRING_LEN);
    return pos;
}

// Convert IPv4 address to network_stack.IpAddress.
pub fn ipv4_to_ip_address(addr: [4]u8, port: u32) network_stack.IpAddress {
    std.debug.assert(port <= network_stack.MAX_PORT);
    return network_stack.IpAddress.init_ipv4(addr, port);
}

// Convert IPv6 address to network_stack.IpAddress.
pub fn ipv6_to_ip_address(addr: [16]u8, port: u32) network_stack.IpAddress {
    std.debug.assert(port <= network_stack.MAX_PORT);
    return network_stack.IpAddress.init_ipv6(addr, port);
}

// Check if IP address is loopback (127.0.0.1 or ::1).
pub fn is_loopback(ip: network_stack.IpAddress) bool {
    std.debug.assert(ip.port <= network_stack.MAX_PORT);
    if (ip.family == network_stack.AddressFamily.ipv4) {
        return ip.address[0] == 127 and ip.address[1] == 0 and
            ip.address[2] == 0 and ip.address[3] == 1;
    } else {
        var all_zero = true;
        var i: u32 = 0;
        while (i < 15) : (i += 1) {
            if (ip.address[i] != 0) {
                all_zero = false;
                break;
            }
        }
        return all_zero and ip.address[15] == 1;
    }
}

// Check if IP address is private (RFC 1918 for IPv4, RFC 4193 for IPv6).
pub fn is_private(ip: network_stack.IpAddress) bool {
    std.debug.assert(ip.port <= network_stack.MAX_PORT);
    if (ip.family == network_stack.AddressFamily.ipv4) {
        const a = ip.address[0];
        const b = ip.address[1];
        if (a == 10) {
            return true;
        }
        if (a == 172 and b >= 16 and b <= 31) {
            return true;
        }
        if (a == 192 and b == 168) {
            return true;
        }
        return false;
    } else {
        return ip.address[0] == 0xFD;
    }
}
