//! Grain OS DNS Query: DNS packet construction and parsing.
//!
//! Why: Implement actual DNS query network communication for hostname resolution.
//! Architecture: DNS packet construction, response parsing, UDP communication, retry logic.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const network_stack = @import("network_stack.zig");
const dns_resolver = @import("dns_resolver.zig");

// Bounded: Max DNS packet size (512 bytes per RFC 1035).
pub const MAX_DNS_PACKET_SIZE: u32 = 512;

// Bounded: Max DNS servers.
pub const MAX_DNS_SERVERS: u32 = 4;

// Bounded: Max retry attempts.
pub const MAX_RETRY_ATTEMPTS: u32 = 3;

// Bounded: Default DNS server port.
pub const DNS_SERVER_PORT: u32 = 53;

// DNS packet header flags.
pub const DNS_FLAGS_QR_QUERY: u16 = 0x0000;
pub const DNS_FLAGS_QR_RESPONSE: u16 = 0x8000;
pub const DNS_FLAGS_OPCODE_STANDARD: u16 = 0x0000;
pub const DNS_FLAGS_RCODE_NOERROR: u16 = 0x0000;

// Build DNS query packet header.
fn build_dns_header(
    transaction_id: u16,
    flags: u16,
    questions: u16,
    answers: u16,
    authorities: u16,
    additionals: u16,
    buf: []u8,
    pos: *u32,
) bool {
    std.debug.assert(buf.len >= 12);
    std.debug.assert(pos.* < buf.len);
    if (pos.* + 12 > buf.len) {
        return false;
    }
    buf[pos.*] = @intCast((transaction_id >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(transaction_id & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast((flags >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(flags & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast((questions >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(questions & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast((answers >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(answers & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast((authorities >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(authorities & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast((additionals >> 8) & 0xFF);
    pos.* += 1;
    buf[pos.*] = @intCast(additionals & 0xFF);
    pos.* += 1;
    std.debug.assert(pos.* <= buf.len);
    return true;
}

// Encode hostname to DNS format (label length + label data).
fn encode_hostname(hostname: []const u8, buf: []u8, pos: *u32) bool {
    std.debug.assert(hostname.len > 0);
    std.debug.assert(hostname.len <= dns_resolver.MAX_HOSTNAME_LEN);
    std.debug.assert(buf.len >= pos.*);
    var start = 0;
    var i: u32 = 0;
    while (i < hostname.len) : (i += 1) {
        if (hostname[i] == '.') {
            const label_len = i - start;
            if (label_len == 0 or label_len > 63) {
                return false;
            }
            if (pos.* + label_len + 1 > buf.len) {
                return false;
            }
            buf[pos.*] = @intCast(label_len);
            pos.* += 1;
            var j: u32 = 0;
            while (j < label_len) : (j += 1) {
                buf[pos.*] = hostname[start + j];
                pos.* += 1;
            }
            start = i + 1;
        }
    }
    const label_len = hostname.len - start;
    if (label_len == 0 or label_len > 63) {
        return false;
    }
    if (pos.* + label_len + 2 > buf.len) {
        return false;
    }
    buf[pos.*] = @intCast(label_len);
    pos.* += 1;
    var j: u32 = 0;
    while (j < label_len) : (j += 1) {
        buf[pos.*] = hostname[start + j];
        pos.* += 1;
    }
    buf[pos.*] = 0;
    pos.* += 1;
    std.debug.assert(pos.* <= buf.len);
    return true;
}

// Build DNS query packet.
pub fn build_dns_query(
    transaction_id: u16,
    hostname: []const u8,
    record_type: dns_resolver.DnsRecordType,
    buf: []u8,
) ?u32 {
    std.debug.assert(hostname.len > 0);
    std.debug.assert(hostname.len <= dns_resolver.MAX_HOSTNAME_LEN);
    std.debug.assert(buf.len >= MAX_DNS_PACKET_SIZE);
    if (buf.len < MAX_DNS_PACKET_SIZE) {
        return null;
    }
    var pos: u32 = 0;
    const flags = DNS_FLAGS_QR_QUERY | DNS_FLAGS_OPCODE_STANDARD;
    if (!build_dns_header(transaction_id, flags, 1, 0, 0, 0, buf, &pos)) {
        return null;
    }
    if (!encode_hostname(hostname, buf, &pos)) {
        return null;
    }
    if (pos + 4 > buf.len) {
        return null;
    }
    const record_type_val: u16 = @intFromEnum(record_type);
    buf[pos] = @intCast((record_type_val >> 8) & 0xFF);
    pos += 1;
    buf[pos] = @intCast(record_type_val & 0xFF);
    pos += 1;
    buf[pos] = 0;
    pos += 1;
    buf[pos] = 1;
    pos += 1;
    std.debug.assert(pos <= MAX_DNS_PACKET_SIZE);
    return pos;
}

// Parse DNS response header.
fn parse_dns_header(
    buf: []const u8,
    transaction_id_out: *u16,
    flags_out: *u16,
    questions_out: *u16,
    answers_out: *u16,
) bool {
    std.debug.assert(buf.len >= 12);
    std.debug.assert(transaction_id_out != null);
    std.debug.assert(flags_out != null);
    std.debug.assert(questions_out != null);
    std.debug.assert(answers_out != null);
    if (buf.len < 12) {
        return false;
    }
    transaction_id_out.* = (@as(u16, buf[0]) << 8) | buf[1];
    flags_out.* = (@as(u16, buf[2]) << 8) | buf[3];
    questions_out.* = (@as(u16, buf[4]) << 8) | buf[5];
    answers_out.* = (@as(u16, buf[6]) << 8) | buf[7];
    std.debug.assert(transaction_id_out.* < 65536);
    return true;
}

// Skip DNS name in response (handles compression pointers).
fn skip_dns_name(buf: []const u8, start_pos: u32, pos_out: *u32) bool {
    std.debug.assert(start_pos < buf.len);
    std.debug.assert(pos_out != null);
    var pos = start_pos;
    var jumped = false;
    while (pos < buf.len) {
        if (buf[pos] == 0) {
            pos += 1;
            pos_out.* = pos;
            return true;
        }
        if ((buf[pos] & 0xC0) == 0xC0) {
            if (pos + 1 >= buf.len) {
                return false;
            }
            const offset = ((@as(u16, buf[pos] & 0x3F) << 8) | buf[pos + 1]);
            if (!jumped and offset < start_pos) {
                pos = offset;
                jumped = true;
            } else {
                pos += 2;
                pos_out.* = pos;
                return true;
            }
        } else {
            const label_len = buf[pos];
            if (label_len > 63) {
                return false;
            }
            pos += 1;
            if (pos + label_len > buf.len) {
                return false;
            }
            pos += label_len;
        }
    }
    return false;
}

// Extract IP address from DNS response answer.
fn extract_ip_from_answer(
    buf: []const u8,
    answer_start: u32,
    record_type: dns_resolver.DnsRecordType,
    ip_out: []u8,
    ip_len_out: *u32,
) bool {
    std.debug.assert(answer_start < buf.len);
    std.debug.assert(ip_out.len >= dns_resolver.MAX_IP_ADDRESS_LEN);
    std.debug.assert(ip_len_out != null);
    var pos = answer_start;
    if (!skip_dns_name(buf, pos, &pos)) {
        return false;
    }
    if (pos + 10 > buf.len) {
        return false;
    }
    pos += 2;
    const answer_record_type = (@as(u16, buf[pos]) << 8) | buf[pos + 1];
    pos += 2;
    if (answer_record_type != @intFromEnum(record_type)) {
        return false;
    }
    pos += 2;
    const data_len = (@as(u16, buf[pos]) << 8) | buf[pos + 1];
    pos += 2;
    if (record_type == .a) {
        if (data_len != 4) {
            return false;
        }
        if (pos + 4 > buf.len) {
            return false;
        }
        if (ip_out.len < 4) {
            return false;
        }
        ip_out[0] = buf[pos];
        ip_out[1] = buf[pos + 1];
        ip_out[2] = buf[pos + 2];
        ip_out[3] = buf[pos + 3];
        ip_len_out.* = 4;
        std.debug.assert(ip_len_out.* == 4);
        return true;
    } else if (record_type == .aaaa) {
        if (data_len != 16) {
            return false;
        }
        if (pos + 16 > buf.len) {
            return false;
        }
        if (ip_out.len < 16) {
            return false;
        }
        var i: u32 = 0;
        while (i < 16) : (i += 1) {
            ip_out[i] = buf[pos + i];
        }
        ip_len_out.* = 16;
        std.debug.assert(ip_len_out.* == 16);
        return true;
    }
    return false;
}

// Parse DNS response packet.
pub fn parse_dns_response(
    buf: []const u8,
    expected_transaction_id: u16,
    record_type: dns_resolver.DnsRecordType,
    ip_out: []u8,
    ip_len_out: *u32,
) bool {
    std.debug.assert(buf.len > 0);
    std.debug.assert(buf.len <= MAX_DNS_PACKET_SIZE);
    std.debug.assert(ip_out.len >= dns_resolver.MAX_IP_ADDRESS_LEN);
    std.debug.assert(ip_len_out != null);
    var transaction_id: u16 = 0;
    var flags: u16 = 0;
    var questions: u16 = 0;
    var answers: u16 = 0;
    if (!parse_dns_header(buf, &transaction_id, &flags, &questions, &answers)) {
        return false;
    }
    if (transaction_id != expected_transaction_id) {
        return false;
    }
    if ((flags & 0x8000) == 0) {
        return false;
    }
    if ((flags & 0x000F) != DNS_FLAGS_RCODE_NOERROR) {
        return false;
    }
    if (answers == 0) {
        return false;
    }
    var pos: u32 = 12;
    var i: u32 = 0;
    while (i < questions) : (i += 1) {
        if (!skip_dns_name(buf, pos, &pos)) {
            return false;
        }
        if (pos + 4 > buf.len) {
            return false;
        }
        pos += 4;
    }
    i = 0;
    while (i < answers) : (i += 1) {
        const answer_start = pos;
        if (extract_ip_from_answer(buf, answer_start, record_type, ip_out, ip_len_out)) {
            std.debug.assert(ip_len_out.* > 0);
            return true;
        }
        if (!skip_dns_name(buf, pos, &pos)) {
            return false;
        }
        if (pos + 10 > buf.len) {
            return false;
        }
        const data_len = (@as(u16, buf[pos + 8]) << 8) | buf[pos + 9];
        pos += 10 + data_len;
        if (pos > buf.len) {
            return false;
        }
    }
    return false;
}
