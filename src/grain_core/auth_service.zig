//! Grain OS Authentication Service: Secure authentication for API endpoints.
//!
//! Why: Provide JWT tokens, password hashing, 2FA, OAuth, sessions for Mobile/Database agents.
//! Architecture: Centralized auth service with JWT, password, 2FA, OAuth, session management.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines, max 100 chars.

const std = @import("std");
const api_server = @import("api_server.zig");

// Constants
pub const MAX_JWT_LEN: u32 = 2048;
pub const MAX_SECRET_LEN: u32 = 256;
pub const MAX_USER_ID_LEN: u32 = 64;
pub const MAX_SESSION_ID_LEN: u32 = 64;
pub const MAX_OTP_CODE_LEN: u32 = 8;
pub const MAX_EMAIL_LEN: u32 = 256;
pub const MAX_PASSWORD_LEN: u32 = 128;
pub const SALT_LEN: u32 = 32;
pub const HASH_LEN: u32 = 32; // SHA-256
pub const HASH_OUTPUT_LEN: u32 = SALT_LEN + HASH_LEN;

// Argon2 constants (for Phase 2)
pub const ARGON2_SALT_LEN: u32 = 16; // Argon2 salt length (RFC 9106)
pub const ARGON2_HASH_LEN: u32 = 32; // Argon2 hash output length
pub const ARGON2_MEMORY_DEFAULT: u32 = 65536; // 64 MB (in KB)
pub const ARGON2_TIME_DEFAULT: u32 = 2; // 2 iterations
pub const ARGON2_PARALLELISM_DEFAULT: u32 = 1; // Single-threaded
pub const ARGON2_MAX_MEMORY: u32 = 1048576; // 1 GB (in KB)
pub const ARGON2_MAX_TIME: u32 = 10;
pub const ARGON2_MAX_PARALLELISM: u32 = 4;
pub const ARGON2_MAX_HASH_STRING_LEN: u32 = 256; // Argon2 hash string format

// Hash format types
pub const HashFormat = enum(u8) {
    sha256,
    argon2id,
};
pub const ACCESS_TOKEN_EXPIRY: u64 = 3600; // 1 hour
pub const REFRESH_TOKEN_EXPIRY: u64 = 604800; // 7 days
pub const SERVICE_ACCOUNT_TOKEN_EXPIRY: u64 = 86400; // 24 hours
pub const OTP_EXPIRY: u64 = 600; // 10 minutes
pub const SESSION_EXPIRY: u64 = 86400; // 24 hours

// JWT Claims structure
pub const JwtClaims = struct {
    user_id: [MAX_USER_ID_LEN]u8,
    user_id_len: u32,
    exp: u64, // Expiration timestamp
    iat: u64, // Issued at timestamp
    token_type: TokenType,
};

// Token types
pub const TokenType = enum(u8) {
    access,
    refresh,
    service_account,
};

// Session structure
pub const Session = struct {
    session_id: [MAX_SESSION_ID_LEN]u8,
    session_id_len: u32,
    user_id: [MAX_USER_ID_LEN]u8,
    user_id_len: u32,
    created_at: u64,
    expires_at: u64,
    is_active: bool,
};

// OTP structure
pub const Otp = struct {
    code: [MAX_OTP_CODE_LEN]u8,
    code_len: u32,
    email: [MAX_EMAIL_LEN]u8,
    email_len: u32,
    created_at: u64,
    expires_at: u64,
    is_used: bool,
};

// OAuth provider types
pub const OAuthProvider = enum(u8) {
    google,
    facebook,
    github,
    apple,
};

// Authentication Service
pub const AuthService = struct {
    secret: [MAX_SECRET_LEN]u8,
    secret_len: u32,
    sessions: [100]Session, // Bounded session storage
    session_count: u32,
    otps: [50]Otp, // Bounded OTP storage
    otp_count: u32,
    revoked_tokens: [200][MAX_JWT_LEN]u8, // Token blacklist
    revoked_count: u32,

    // Initialize authentication service with secret
    pub fn init(secret: []const u8) AuthService {
        std.debug.assert(secret.len > 0);
        std.debug.assert(secret.len <= MAX_SECRET_LEN);
        var service = AuthService{
            .secret = undefined,
            .secret_len = @intCast(secret.len),
            .sessions = undefined,
            .session_count = 0,
            .otps = undefined,
            .otp_count = 0,
            .revoked_tokens = undefined,
            .revoked_count = 0,
        };
        std.mem.copyForwards(u8, &service.secret, secret);
        std.mem.set(u8, &service.sessions, 0);
        std.mem.set(u8, &service.otps, 0);
        std.mem.set(u8, &service.revoked_tokens, 0);
        std.debug.assert(service.secret_len > 0);
        return service;
    }

    // Generate JWT access token
    pub fn generate_access_token(
        self: *AuthService,
        user_id: []const u8,
        current_time: u64,
        token_out: []u8,
    ) u32 {
        std.debug.assert(user_id.len > 0);
        std.debug.assert(user_id.len <= MAX_USER_ID_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(token_out.len >= MAX_JWT_LEN);
        var claims = JwtClaims{
            .user_id = undefined,
            .user_id_len = @intCast(user_id.len),
            .exp = current_time + ACCESS_TOKEN_EXPIRY,
            .iat = current_time,
            .token_type = TokenType.access,
        };
        std.mem.copyForwards(u8, &claims.user_id, user_id);
        const token_len = generate_jwt_token(
            &claims,
            self.secret[0..self.secret_len],
            token_out,
        );
        std.debug.assert(token_len > 0);
        std.debug.assert(token_len <= MAX_JWT_LEN);
        return token_len;
    }

    // Generate JWT refresh token
    pub fn generate_refresh_token(
        self: *AuthService,
        user_id: []const u8,
        current_time: u64,
        token_out: []u8,
    ) u32 {
        std.debug.assert(user_id.len > 0);
        std.debug.assert(user_id.len <= MAX_USER_ID_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(token_out.len >= MAX_JWT_LEN);
        var claims = JwtClaims{
            .user_id = undefined,
            .user_id_len = @intCast(user_id.len),
            .exp = current_time + REFRESH_TOKEN_EXPIRY,
            .iat = current_time,
            .token_type = TokenType.refresh,
        };
        std.mem.copyForwards(u8, &claims.user_id, user_id);
        const token_len = generate_jwt_token(
            &claims,
            self.secret[0..self.secret_len],
            token_out,
        );
        std.debug.assert(token_len > 0);
        std.debug.assert(token_len <= MAX_JWT_LEN);
        return token_len;
    }

    // Generate service account token for service-to-service auth.
    pub fn generate_service_account_token(
        self: *AuthService,
        service_id: []const u8,
        current_time: u64,
        token_out: []u8,
    ) u32 {
        std.debug.assert(service_id.len > 0);
        std.debug.assert(service_id.len <= MAX_USER_ID_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(token_out.len >= MAX_JWT_LEN);
        var claims = JwtClaims{
            .user_id = undefined,
            .user_id_len = @intCast(service_id.len),
            .exp = current_time + SERVICE_ACCOUNT_TOKEN_EXPIRY,
            .iat = current_time,
            .token_type = TokenType.service_account,
        };
        std.mem.copyForwards(u8, &claims.user_id, service_id);
        const token_len = generate_jwt_token(
            &claims,
            self.secret[0..self.secret_len],
            token_out,
        );
        std.debug.assert(token_len > 0);
        std.debug.assert(token_len <= MAX_JWT_LEN);
        return token_len;
    }

    // Validate JWT token
    pub fn validate_jwt_token(
        self: *AuthService,
        token: []const u8,
        current_time: u64,
        claims_out: *JwtClaims,
    ) bool {
        std.debug.assert(token.len > 0);
        std.debug.assert(token.len <= MAX_JWT_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(claims_out != null);
        if (is_token_revoked(self, token)) {
            return false;
        }
        const is_valid = validate_jwt(
            token,
            self.secret[0..self.secret_len],
            current_time,
            claims_out,
        );
        if (!is_valid) {
            return false;
        }
        if (claims_out.exp < current_time) {
            return false;
        }
        std.debug.assert(claims_out.user_id_len > 0);
        return true;
    }

    // Revoke JWT token (add to blacklist)
    pub fn revoke_token(self: *AuthService, token: []const u8) bool {
        std.debug.assert(token.len > 0);
        std.debug.assert(token.len <= MAX_JWT_LEN);
        if (self.revoked_count >= 200) {
            return false;
        }
        if (token.len > MAX_JWT_LEN) {
            return false;
        }
        std.mem.copyForwards(
            u8,
            &self.revoked_tokens[self.revoked_count],
            token,
        );
        self.revoked_count += 1;
        std.debug.assert(self.revoked_count <= 200);
        return true;
    }

    // Check if token is revoked
    fn is_token_revoked(self: *const AuthService, token: []const u8) bool {
        std.debug.assert(token.len > 0);
        std.debug.assert(token.len <= MAX_JWT_LEN);
        var i: u32 = 0;
        while (i < self.revoked_count) : (i += 1) {
            const revoked_token = self.revoked_tokens[i][0..token.len];
            if (std.mem.eql(u8, revoked_token, token)) {
                return true;
            }
        }
        return false;
    }

    // Detect hash format (SHA-256 vs Argon2id) - for migration support
    pub fn detect_hash_format(stored_hash: []const u8) HashFormat {
        std.debug.assert(stored_hash.len > 0);
        if (stored_hash.len == HASH_OUTPUT_LEN) {
            return HashFormat.sha256;
        }
        if (stored_hash.len > 20 and stored_hash[0] == '$') {
            const argon2id_prefix = "$argon2id$";
            if (stored_hash.len >= argon2id_prefix.len) {
                var i: u32 = 0;
                while (i < argon2id_prefix.len) : (i += 1) {
                    if (stored_hash[i] != argon2id_prefix[i]) {
                        return HashFormat.sha256;
                    }
                }
                return HashFormat.argon2id;
            }
        }
        return HashFormat.sha256;
    }

    // Hash password (SHA-256 with salt) - static function
    pub fn hash_password_static(
        password: []const u8,
        hash_out: []u8,
    ) void {
        std.debug.assert(password.len > 0);
        std.debug.assert(password.len <= MAX_PASSWORD_LEN);
        std.debug.assert(hash_out.len >= HASH_OUTPUT_LEN);
        var salt: [SALT_LEN]u8 = undefined;
        std.crypto.random.bytes(&salt);
        var combined: [MAX_PASSWORD_LEN + SALT_LEN]u8 = undefined;
        std.mem.copyForwards(u8, combined[0..password.len], password);
        std.mem.copyForwards(u8, combined[password.len..password.len + SALT_LEN], &salt);
        var hash: [HASH_LEN]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(combined[0..password.len + SALT_LEN], &hash, .{});
        std.mem.copyForwards(u8, hash_out[0..SALT_LEN], &salt);
        std.mem.copyForwards(u8, hash_out[SALT_LEN..SALT_LEN + HASH_LEN], &hash);
        std.debug.assert(hash_out.len >= HASH_OUTPUT_LEN);
    }

    // Verify password - static function (supports SHA-256 and Argon2id)
    pub fn verify_password_static(
        password: []const u8,
        stored_hash: []const u8,
    ) bool {
        std.debug.assert(password.len > 0);
        std.debug.assert(password.len <= MAX_PASSWORD_LEN);
        std.debug.assert(stored_hash.len > 0);
        const format = detect_hash_format(stored_hash);
        if (format == HashFormat.argon2id) {
            return verify_argon2id_static(password, stored_hash);
        }
        if (stored_hash.len < HASH_OUTPUT_LEN) {
            return false;
        }
        const salt = stored_hash[0..SALT_LEN];
        const stored_hash_only = stored_hash[SALT_LEN..SALT_LEN + HASH_LEN];
        var combined: [MAX_PASSWORD_LEN + SALT_LEN]u8 = undefined;
        std.mem.copyForwards(u8, combined[0..password.len], password);
        std.mem.copyForwards(u8, combined[password.len..password.len + SALT_LEN], salt);
        var computed_hash: [HASH_LEN]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(combined[0..password.len + SALT_LEN], &computed_hash, .{});
        const matches = std.mem.eql(u8, &computed_hash, stored_hash_only);
        std.debug.assert(password.len > 0);
        std.debug.assert(stored_hash.len >= HASH_OUTPUT_LEN);
        return matches;
    }

    // Create session
    pub fn create_session(
        self: *AuthService,
        user_id: []const u8,
        current_time: u64,
        session_out: *Session,
    ) bool {
        std.debug.assert(user_id.len > 0);
        std.debug.assert(user_id.len <= MAX_USER_ID_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(session_out != null);
        if (self.session_count >= 100) {
            return false;
        }
        var session_id: [MAX_SESSION_ID_LEN]u8 = undefined;
        std.crypto.random.bytes(&session_id);
        std.mem.copyForwards(u8, &session_out.session_id, &session_id);
        session_out.session_id_len = MAX_SESSION_ID_LEN;
        std.mem.copyForwards(u8, &session_out.user_id, user_id);
        session_out.user_id_len = @intCast(user_id.len);
        session_out.created_at = current_time;
        session_out.expires_at = current_time + SESSION_EXPIRY;
        session_out.is_active = true;
        self.sessions[self.session_count] = session_out.*;
        self.session_count += 1;
        std.debug.assert(self.session_count <= 100);
        return true;
    }

    // Validate session
    pub fn validate_session(
        self: *AuthService,
        session_id: []const u8,
        current_time: u64,
        session_out: ?*Session,
    ) bool {
        std.debug.assert(session_id.len > 0);
        std.debug.assert(session_id.len <= MAX_SESSION_ID_LEN);
        std.debug.assert(current_time > 0);
        var i: u32 = 0;
        while (i < self.session_count) : (i += 1) {
            const session = &self.sessions[i];
            if (!session.is_active) {
                continue;
            }
            if (session.expires_at < current_time) {
                session.is_active = false;
                continue;
            }
            const session_id_bytes = session.session_id[0..session.session_id_len];
            if (std.mem.eql(u8, session_id_bytes, session_id)) {
                if (session_out) |out| {
                    out.* = session.*;
                }
                return true;
            }
        }
        return false;
    }

    // Revoke session (logout)
    pub fn revoke_session(self: *AuthService, session_id: []const u8) bool {
        std.debug.assert(session_id.len > 0);
        std.debug.assert(session_id.len <= MAX_SESSION_ID_LEN);
        var i: u32 = 0;
        while (i < self.session_count) : (i += 1) {
            const session = &self.sessions[i];
            const session_id_bytes = session.session_id[0..session.session_id_len];
            if (std.mem.eql(u8, session_id_bytes, session_id)) {
                session.is_active = false;
                return true;
            }
        }
        return false;
    }

    // Generate OTP code
    pub fn generate_otp(
        self: *AuthService,
        email: []const u8,
        current_time: u64,
        otp_out: *Otp,
    ) bool {
        std.debug.assert(email.len > 0);
        std.debug.assert(email.len <= MAX_EMAIL_LEN);
        std.debug.assert(current_time > 0);
        std.debug.assert(otp_out != null);
        if (self.otp_count >= 50) {
            return false;
        }
        var code_bytes: [4]u8 = undefined;
        std.crypto.random.bytes(&code_bytes);
        var code: [MAX_OTP_CODE_LEN]u8 = undefined;
        var code_len: u32 = 0;
        var i: u32 = 0;
        while (i < 4 and code_len < MAX_OTP_CODE_LEN) : (i += 1) {
            const digit = code_bytes[i] % 10;
            code[code_len] = '0' + digit;
            code_len += 1;
        }
        std.mem.copyForwards(u8, &otp_out.code, code[0..code_len]);
        otp_out.code_len = code_len;
        std.mem.copyForwards(u8, &otp_out.email, email);
        otp_out.email_len = @intCast(email.len);
        otp_out.created_at = current_time;
        otp_out.expires_at = current_time + OTP_EXPIRY;
        otp_out.is_used = false;
        self.otps[self.otp_count] = otp_out.*;
        self.otp_count += 1;
        std.debug.assert(self.otp_count <= 50);
        return true;
    }

    // Validate OTP code
    pub fn validate_otp(
        self: *AuthService,
        email: []const u8,
        code: []const u8,
        current_time: u64,
    ) bool {
        std.debug.assert(email.len > 0);
        std.debug.assert(email.len <= MAX_EMAIL_LEN);
        std.debug.assert(code.len > 0);
        std.debug.assert(code.len <= MAX_OTP_CODE_LEN);
        std.debug.assert(current_time > 0);
        var i: u32 = 0;
        while (i < self.otp_count) : (i += 1) {
            const otp = &self.otps[i];
            if (otp.is_used) {
                continue;
            }
            if (otp.expires_at < current_time) {
                continue;
            }
            const otp_email = otp.email[0..otp.email_len];
            if (!std.mem.eql(u8, otp_email, email)) {
                continue;
            }
            const otp_code = otp.code[0..otp.code_len];
            if (std.mem.eql(u8, otp_code, code)) {
                otp.is_used = true;
                return true;
            }
        }
        return false;
    }

    // Generate TOTP code (2FA)
    pub fn generate_totp(secret: []const u8, timestamp: u64) u32 {
        std.debug.assert(secret.len > 0);
        std.debug.assert(timestamp > 0);
        const time_step: u64 = 30;
        const time_counter = timestamp / time_step;
        var time_bytes: [8]u8 = undefined;
        var i: u32 = 0;
        var counter = time_counter;
        while (i < 8) : (i += 1) {
            time_bytes[7 - i] = @truncate(counter & 0xFF);
            counter >>= 8;
        }
        var hmac: [20]u8 = undefined;
        hmac_sha1(secret, &time_bytes, &hmac);
        const offset = hmac[19] & 0x0F;
        const code = ((@as(u32, hmac[offset]) & 0x7F) << 24) |
            (@as(u32, hmac[offset + 1]) << 16) |
            (@as(u32, hmac[offset + 2]) << 8) |
            @as(u32, hmac[offset + 3]);
        const totp_code = code % 1000000;
        std.debug.assert(totp_code < 1000000);
        return totp_code;
    }

    // Validate TOTP code (2FA)
    pub fn validate_totp(
        secret: []const u8,
        code: u32,
        timestamp: u64,
    ) bool {
        std.debug.assert(secret.len > 0);
        std.debug.assert(code < 1000000);
        std.debug.assert(timestamp > 0);
        const generated = generate_totp(secret, timestamp);
        if (generated == code) {
            return true;
        }
        const time_step: u64 = 30;
        const prev_timestamp = timestamp - time_step;
        const prev_generated = generate_totp(secret, prev_timestamp);
        if (prev_generated == code) {
            return true;
        }
        const next_timestamp = timestamp + time_step;
        const next_generated = generate_totp(secret, next_timestamp);
        if (next_generated == code) {
            return true;
        }
        return false;
    }
};

// HMAC-SHA1 for TOTP
fn hmac_sha1(key: []const u8, message: []const u8, output: []u8) void {
    std.debug.assert(key.len > 0);
    std.debug.assert(message.len > 0);
    std.debug.assert(output.len >= 20);
    const block_size: u32 = 64;
    var ipad_key: [block_size]u8 = undefined;
    var opad_key: [block_size]u8 = undefined;
    if (key.len > block_size) {
        var key_hash: [20]u8 = undefined;
        std.crypto.hash.sha1.Sha1.hash(key, &key_hash, .{});
        std.mem.set(u8, &ipad_key, 0);
        std.mem.copyForwards(u8, ipad_key[0..20], &key_hash);
    } else {
        std.mem.set(u8, &ipad_key, 0);
        std.mem.copyForwards(u8, ipad_key[0..key.len], key);
    }
    var i: u32 = 0;
    while (i < block_size) : (i += 1) {
        opad_key[i] = ipad_key[i];
        ipad_key[i] ^= 0x36;
        opad_key[i] ^= 0x5C;
    }
    var inner_hash: [20]u8 = undefined;
    var inner_input: [block_size + 256]u8 = undefined;
    std.mem.copyForwards(u8, inner_input[0..block_size], &ipad_key);
    if (message.len <= 256) {
        std.mem.copyForwards(
            u8,
            inner_input[block_size..block_size + message.len],
            message,
        );
        std.crypto.hash.sha1.Sha1.hash(
            inner_input[0..block_size + message.len],
            &inner_hash,
            .{},
        );
    } else {
        std.crypto.hash.sha1.Sha1.hash(message, &inner_hash, .{});
    }
    var outer_input: [block_size + 20]u8 = undefined;
    std.mem.copyForwards(u8, outer_input[0..block_size], &opad_key);
    std.mem.copyForwards(u8, outer_input[block_size..block_size + 20], &inner_hash);
    std.crypto.hash.sha1.Sha1.hash(
        outer_input[0..block_size + 20],
        output[0..20],
        .{},
    );
    std.debug.assert(output.len >= 20);
}

// Convert u64 to string (helper for JWT claims JSON)
fn u64_to_string(value: u64, str_out: []u8) u32 {
    std.debug.assert(str_out.len >= 20);
    if (value == 0) {
        str_out[0] = '0';
        return 1;
    }
    var remaining = value;
    var temp_str: [20]u8 = undefined;
    var temp_idx: u32 = 19;
    while (remaining > 0) {
        temp_str[temp_idx] = '0' + @as(u8, @intCast(remaining % 10));
        remaining /= 10;
        if (temp_idx == 0) {
            break;
        }
        temp_idx -= 1;
    }
    const str_len = 20 - temp_idx;
    std.mem.copyForwards(u8, str_out[0..str_len], temp_str[temp_idx + 1..20]);
    std.debug.assert(str_len > 0);
    std.debug.assert(str_len <= 20);
    return str_len;
}

// Build claims JSON string from JwtClaims (helper for JWT generation)
fn build_claims_json(claims: *const JwtClaims, json_out: []u8) u32 {
    std.debug.assert(claims != null);
    std.debug.assert(json_out.len >= 512);
    var json_len: u32 = 0;
    json_out[json_len] = '{';
    json_len += 1;
    json_out[json_len] = '"';
    json_len += 1;
    std.mem.copyForwards(u8, json_out[json_len..], "user_id");
    json_len += 6;
    json_out[json_len] = '"';
    json_len += 1;
    json_out[json_len] = ':';
    json_len += 1;
    json_out[json_len] = '"';
    json_len += 1;
    std.mem.copyForwards(
        u8,
        json_out[json_len..],
        claims.user_id[0..claims.user_id_len],
    );
    json_len += claims.user_id_len;
    json_out[json_len] = '"';
    json_len += 1;
    json_out[json_len] = ',';
    json_len += 1;
    json_out[json_len] = '"';
    json_len += 1;
    std.mem.copyForwards(u8, json_out[json_len..], "exp");
    json_len += 3;
    json_out[json_len] = '"';
    json_len += 1;
    json_out[json_len] = ':';
    json_len += 1;
    var exp_str: [20]u8 = undefined;
    const exp_str_len = u64_to_string(claims.exp, &exp_str);
    std.mem.copyForwards(u8, json_out[json_len..], exp_str[0..exp_str_len]);
    json_len += exp_str_len;
    json_out[json_len] = ',';
    json_len += 1;
    json_out[json_len] = '"';
    json_len += 1;
    std.mem.copyForwards(u8, json_out[json_len..], "iat");
    json_len += 3;
    json_out[json_len] = '"';
    json_len += 1;
    json_out[json_len] = ':';
    json_len += 1;
    var iat_str: [20]u8 = undefined;
    const iat_str_len = u64_to_string(claims.iat, &iat_str);
    std.mem.copyForwards(u8, json_out[json_len..], iat_str[0..iat_str_len]);
    json_len += iat_str_len;
    json_out[json_len] = '}';
    json_len += 1;
    std.debug.assert(json_len <= json_out.len);
    return json_len;
}

// Assemble JWT token from parts (header.claims.signature)
fn assemble_jwt_token(
    header_encoded: []const u8,
    claims_encoded: []const u8,
    signature_encoded: []const u8,
    token_out: []u8,
) u32 {
    std.debug.assert(header_encoded.len > 0);
    std.debug.assert(claims_encoded.len > 0);
    std.debug.assert(signature_encoded.len > 0);
    std.debug.assert(token_out.len >= MAX_JWT_LEN);
    var token_len: u32 = 0;
    std.mem.copyForwards(u8, token_out[token_len..], header_encoded);
    token_len += @intCast(header_encoded.len);
    token_out[token_len] = '.';
    token_len += 1;
    std.mem.copyForwards(u8, token_out[token_len..], claims_encoded);
    token_len += @intCast(claims_encoded.len);
    token_out[token_len] = '.';
    token_len += 1;
    std.mem.copyForwards(u8, token_out[token_len..], signature_encoded);
    token_len += @intCast(signature_encoded.len);
    std.debug.assert(token_len <= token_out.len);
    return token_len;
}

// Generate JWT token (internal helper)
fn generate_jwt_token(
    claims: *const JwtClaims,
    secret: []const u8,
    token_out: []u8,
) u32 {
    std.debug.assert(claims != null);
    std.debug.assert(secret.len > 0);
    std.debug.assert(token_out.len >= MAX_JWT_LEN);
    const header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
    var header_encoded: [256]u8 = undefined;
    const header_encoded_len = base64url_encode(header, &header_encoded);
    var claims_json: [512]u8 = undefined;
    const claims_json_len = build_claims_json(claims, &claims_json);
    var claims_encoded: [512]u8 = undefined;
    const claims_encoded_len = base64url_encode(
        claims_json[0..claims_json_len],
        &claims_encoded,
    );
    var message: [1024]u8 = undefined;
    std.mem.copyForwards(
        u8,
        message[0..header_encoded_len],
        header_encoded[0..header_encoded_len],
    );
    message[header_encoded_len] = '.';
    std.mem.copyForwards(
        u8,
        message[header_encoded_len + 1..header_encoded_len + 1 + claims_encoded_len],
        claims_encoded[0..claims_encoded_len],
    );
    const message_len = header_encoded_len + 1 + claims_encoded_len;
    var signature: [32]u8 = undefined;
    hmac_sha256(secret, message[0..message_len], &signature);
    var signature_encoded: [64]u8 = undefined;
    const signature_encoded_len = base64url_encode(&signature, &signature_encoded);
    const token_len = assemble_jwt_token(
        header_encoded[0..header_encoded_len],
        claims_encoded[0..claims_encoded_len],
        signature_encoded[0..signature_encoded_len],
        token_out,
    );
    std.debug.assert(token_len <= token_out.len);
    return token_len;
}

// Parse JWT token into three parts (header, claims, signature)
fn parse_jwt_parts(token: []const u8, parts_out: *[3][]const u8) bool {
    std.debug.assert(token.len > 0);
    std.debug.assert(token.len <= MAX_JWT_LEN);
    var part_count: u32 = 0;
    var start: u32 = 0;
    var i: u32 = 0;
    while (i < token.len and part_count < 3) : (i += 1) {
        if (token[i] == '.') {
            parts_out[part_count] = token[start..i];
            part_count += 1;
            start = i + 1;
        }
    }
    if (part_count < 2) {
        return false;
    }
    parts_out[part_count] = token[start..];
    part_count += 1;
    if (part_count != 3) {
        return false;
    }
    std.debug.assert(part_count == 3);
    return true;
}

// Verify JWT signature matches computed signature
fn verify_jwt_signature(
    header: []const u8,
    claims: []const u8,
    signature: []const u8,
    secret: []const u8,
) bool {
    std.debug.assert(header.len > 0);
    std.debug.assert(claims.len > 0);
    std.debug.assert(signature.len > 0);
    std.debug.assert(secret.len > 0);
    var message: [1024]u8 = undefined;
    std.mem.copyForwards(u8, message[0..header.len], header);
    message[header.len] = '.';
    std.mem.copyForwards(
        u8,
        message[header.len + 1..header.len + 1 + claims.len],
        claims,
    );
    const message_len = header.len + 1 + claims.len;
    var computed_sig: [32]u8 = undefined;
    hmac_sha256(secret, message[0..message_len], &computed_sig);
    var computed_sig_encoded: [64]u8 = undefined;
    const computed_sig_len = base64url_encode(&computed_sig, &computed_sig_encoded);
    if (computed_sig_len != signature.len) {
        return false;
    }
    if (!std.mem.eql(
        u8,
        computed_sig_encoded[0..computed_sig_len],
        signature,
    )) {
        return false;
    }
    std.debug.assert(computed_sig_len == signature.len);
    return true;
}

// Extract exp value from decoded claims JSON
fn extract_exp_from_json(claims_json: []const u8, exp_out: *u64) bool {
    std.debug.assert(claims_json.len > 0);
    std.debug.assert(claims_json.len <= 512);
    std.debug.assert(exp_out != null);
    var exp_value: u64 = 0;
    var i: u32 = 0;
    while (i < claims_json.len) : (i += 1) {
        if (i + 5 < claims_json.len and
            std.mem.eql(u8, claims_json[i..i + 5], "\"exp\""))
        {
            var j = i + 5;
            while (j < claims_json.len and claims_json[j] != ':') : (j += 1) {}
            j += 1;
            while (j < claims_json.len and
                (claims_json[j] == ' ' or claims_json[j] == '\t')) : (j += 1) {}
            exp_value = 0;
            while (j < claims_json.len and
                claims_json[j] >= '0' and claims_json[j] <= '9') : (j += 1)
            {
                exp_value = exp_value * 10 + @as(u64, @intCast(claims_json[j] - '0'));
            }
            exp_out.* = exp_value;
            return true;
        }
    }
    return false;
}

// Extract user_id from decoded claims JSON
fn extract_user_id_from_json(
    claims_json: []const u8,
    user_id_out: *JwtClaims,
) bool {
    std.debug.assert(claims_json.len > 0);
    std.debug.assert(claims_json.len <= 512);
    std.debug.assert(user_id_out != null);
    var user_id_start: ?u32 = null;
    var user_id_end: ?u32 = null;
    var i: u32 = 0;
    while (i < claims_json.len) : (i += 1) {
        if (i + 8 < claims_json.len and
            std.mem.eql(u8, claims_json[i..i + 8], "\"user_id\""))
        {
            var j = i + 8;
            while (j < claims_json.len and claims_json[j] != ':') : (j += 1) {}
            j += 1;
            while (j < claims_json.len and
                (claims_json[j] == ' ' or claims_json[j] == '\t')) : (j += 1) {}
            if (j < claims_json.len and claims_json[j] == '"') {
                j += 1;
                user_id_start = j;
                while (j < claims_json.len and claims_json[j] != '"') : (j += 1) {}
                user_id_end = j;
                break;
            }
        }
    }
    if (user_id_start) |start_idx| {
        if (user_id_end) |end_idx| {
            const user_id_len = end_idx - start_idx;
            if (user_id_len > MAX_USER_ID_LEN) {
                return false;
            }
            std.mem.copyForwards(
                u8,
                &user_id_out.user_id,
                claims_json[start_idx..end_idx],
            );
            user_id_out.user_id_len = user_id_len;
            std.debug.assert(user_id_out.user_id_len > 0);
            return true;
        }
    }
    return false;
}

// Extract exp and user_id from decoded claims JSON
fn extract_claims_fields(
    claims_json: []const u8,
    exp_out: *u64,
    user_id_out: *JwtClaims,
) bool {
    std.debug.assert(claims_json.len > 0);
    std.debug.assert(claims_json.len <= 512);
    std.debug.assert(exp_out != null);
    std.debug.assert(user_id_out != null);
    if (!extract_exp_from_json(claims_json, exp_out)) {
        return false;
    }
    if (!extract_user_id_from_json(claims_json, user_id_out)) {
        return false;
    }
    std.debug.assert(user_id_out.user_id_len > 0);
    return true;
}

// Validate JWT token (internal helper)
fn validate_jwt(
    token: []const u8,
    secret: []const u8,
    current_time: u64,
    claims_out: *JwtClaims,
) bool {
    std.debug.assert(token.len > 0);
    std.debug.assert(token.len <= MAX_JWT_LEN);
    std.debug.assert(secret.len > 0);
    std.debug.assert(current_time > 0);
    std.debug.assert(claims_out != null);
    var parts: [3][]const u8 = undefined;
    if (!parse_jwt_parts(token, &parts)) {
        return false;
    }
    if (!verify_jwt_signature(parts[0], parts[1], parts[2], secret)) {
        return false;
    }
    var claims_decoded: [512]u8 = undefined;
    const claims_decoded_len = base64url_decode(parts[1], &claims_decoded);
    var exp_value: u64 = 0;
    if (!extract_claims_fields(
        claims_decoded[0..claims_decoded_len],
        &exp_value,
        claims_out,
    )) {
        return false;
    }
    claims_out.exp = exp_value;
    claims_out.iat = current_time;
    claims_out.token_type = TokenType.access;
    std.debug.assert(claims_out.user_id_len > 0);
    return true;
}

// Base64URL encoding
fn base64url_encode(input: []const u8, output: []u8) u32 {
    std.debug.assert(input.len > 0);
    std.debug.assert(output.len >= (input.len * 4 / 3 + 4));
    const base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var i: u32 = 0;
    var out_idx: u32 = 0;
    while (i < input.len) {
        const byte1 = input[i];
        i += 1;
        if (i < input.len) {
            const byte2 = input[i];
            i += 1;
            if (i < input.len) {
                const byte3 = input[i];
                i += 1;
                const b1 = (byte1 >> 2) & 0x3F;
                const b2 = ((byte1 & 0x03) << 4) | ((byte2 >> 4) & 0x0F);
                const b3 = ((byte2 & 0x0F) << 2) | ((byte3 >> 6) & 0x03);
                const b4 = byte3 & 0x3F;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b1)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b2)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b3)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b4)];
                out_idx += 1;
            } else {
                const b1 = (byte1 >> 2) & 0x3F;
                const b2 = ((byte1 & 0x03) << 4) | ((byte2 >> 4) & 0x0F);
                const b3 = (byte2 & 0x0F) << 2;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b1)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b2)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b3)];
                out_idx += 1;
                if (out_idx < output.len) output[out_idx] = '=';
                out_idx += 1;
            }
        } else {
            const b1 = (byte1 >> 2) & 0x3F;
            const b2 = (byte1 & 0x03) << 4;
            if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b1)];
            out_idx += 1;
            if (out_idx < output.len) output[out_idx] = base64_chars[@intCast(b2)];
            out_idx += 1;
            if (out_idx < output.len) output[out_idx] = '=';
            out_idx += 1;
            if (out_idx < output.len) output[out_idx] = '=';
            out_idx += 1;
        }
    }
    std.debug.assert(out_idx <= output.len);
    return out_idx;
}

// Convert Base64URL character to its numeric value
fn base64url_char_to_value(char: u8) ?u8 {
    const base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var j: u32 = 0;
    while (j < 64) : (j += 1) {
        if (base64_chars[j] == char) {
            return @intCast(j);
        }
    }
    return null;
}

// Decode 4 Base64URL characters to 3 bytes (helper for base64url_decode)
fn decode_base64url_4chars(
    chars: [4]u8,
    output: []u8,
    out_idx: u32,
) ?u32 {
    std.debug.assert(output.len > out_idx);
    std.debug.assert(output.len >= out_idx + 3);
    var values: [4]u8 = undefined;
    var i: u32 = 0;
    while (i < 4) : (i += 1) {
        const val = base64url_char_to_value(chars[i]);
        if (val) |v| {
            values[i] = v;
        } else {
            return null;
        }
    }
    const new_idx = out_idx + 3;
    if (new_idx > output.len) {
        return null;
    }
    output[out_idx] = (values[0] << 2) | (values[1] >> 4);
    output[out_idx + 1] = ((values[1] & 0x0F) << 4) | (values[2] >> 2);
    output[out_idx + 2] = ((values[2] & 0x03) << 6) | values[3];
    std.debug.assert(new_idx <= output.len);
    return new_idx;
}

// Decode 3 Base64URL characters to 2 bytes (padding case)
fn decode_base64url_3chars(
    chars: [3]u8,
    output: []u8,
    out_idx: u32,
) ?u32 {
    std.debug.assert(output.len > out_idx);
    std.debug.assert(output.len >= out_idx + 2);
    var values: [3]u8 = undefined;
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        const val = base64url_char_to_value(chars[i]);
        if (val) |v| {
            values[i] = v;
        } else {
            return null;
        }
    }
    const new_idx = out_idx + 2;
    if (new_idx > output.len) {
        return null;
    }
    output[out_idx] = (values[0] << 2) | (values[1] >> 4);
    output[out_idx + 1] = ((values[1] & 0x0F) << 4) | (values[2] >> 2);
    std.debug.assert(new_idx <= output.len);
    return new_idx;
}

// Decode 2 Base64URL characters to 1 byte (padding case)
fn decode_base64url_2chars(
    chars: [2]u8,
    output: []u8,
    out_idx: u32,
) ?u32 {
    std.debug.assert(output.len > out_idx);
    const val1 = base64url_char_to_value(chars[0]) orelse return null;
    const val2 = base64url_char_to_value(chars[1]) orelse return null;
    const new_idx = out_idx + 1;
    if (new_idx > output.len) {
        return null;
    }
    output[out_idx] = (val1 << 2) | (val2 >> 4);
    std.debug.assert(new_idx <= output.len);
    return new_idx;
}

// Base64URL decoding
fn base64url_decode(input: []const u8, output: []u8) u32 {
    std.debug.assert(input.len > 0);
    std.debug.assert(output.len >= (input.len * 3 / 4));
    var out_idx: u32 = 0;
    var i: u32 = 0;
    while (i < input.len) {
        if (input[i] == '=') {
            break;
        }
        if (i + 3 < input.len and input[i + 1] != '=' and
            input[i + 2] != '=' and input[i + 3] != '=')
        {
            const chars = [4]u8{ input[i], input[i + 1], input[i + 2], input[i + 3] };
            const new_idx = decode_base64url_4chars(chars, output, out_idx) orelse break;
            out_idx = new_idx;
            i += 4;
        } else if (i + 2 < input.len and input[i + 1] != '=' and
            input[i + 2] != '=')
        {
            const chars = [3]u8{ input[i], input[i + 1], input[i + 2] };
            const new_idx = decode_base64url_3chars(chars, output, out_idx) orelse break;
            out_idx = new_idx;
            break;
        } else if (i + 1 < input.len and input[i + 1] != '=') {
            const chars = [2]u8{ input[i], input[i + 1] };
            const new_idx = decode_base64url_2chars(chars, output, out_idx) orelse break;
            out_idx = new_idx;
            break;
        } else {
            break;
        }
    }
    std.debug.assert(out_idx <= output.len);
    return out_idx;
}

// HMAC-SHA256 for JWT signatures
fn hmac_sha256(key: []const u8, message: []const u8, output: []u8) void {
    std.debug.assert(key.len > 0);
    std.debug.assert(message.len > 0);
    std.debug.assert(output.len >= 32);
    const block_size: u32 = 64;
    var ipad_key: [block_size]u8 = undefined;
    var opad_key: [block_size]u8 = undefined;
    if (key.len > block_size) {
        var key_hash: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(key, &key_hash, .{});
        std.mem.set(u8, &ipad_key, 0);
        std.mem.copyForwards(u8, ipad_key[0..32], &key_hash);
    } else {
        std.mem.set(u8, &ipad_key, 0);
        std.mem.copyForwards(u8, ipad_key[0..key.len], key);
    }
    var i: u32 = 0;
    while (i < block_size) : (i += 1) {
        opad_key[i] = ipad_key[i];
        ipad_key[i] ^= 0x36;
        opad_key[i] ^= 0x5C;
    }
    var inner_hash: [32]u8 = undefined;
    var inner_input: [block_size + 256]u8 = undefined;
    std.mem.copyForwards(u8, inner_input[0..block_size], &ipad_key);
    if (message.len <= 256) {
        std.mem.copyForwards(
            u8,
            inner_input[block_size..block_size + message.len],
            message,
        );
        std.crypto.hash.sha2.Sha256.hash(
            inner_input[0..block_size + message.len],
            &inner_hash,
            .{},
        );
    } else {
        std.crypto.hash.sha2.Sha256.hash(message, &inner_hash, .{});
    }
    var outer_input: [block_size + 32]u8 = undefined;
    std.mem.copyForwards(u8, outer_input[0..block_size], &opad_key);
    std.mem.copyForwards(u8, outer_input[block_size..block_size + 32], &inner_hash);
    std.crypto.hash.sha2.Sha256.hash(
        outer_input[0..block_size + 32],
        output[0..32],
        .{},
    );
    std.debug.assert(output.len >= 32);
}

// ============================================================================
// Argon2 Password Hashing (Phase 2 - Implementation in Progress)
// ============================================================================

// Argon2 parameters structure
pub const Argon2Params = struct {
    memory_kb: u32, // Memory cost (in KB)
    time: u32, // Number of iterations
    parallelism: u32, // Number of threads/lanes
};

// Get default Argon2 parameters
pub fn get_default_argon2_params() Argon2Params {
    return Argon2Params{
        .memory_kb = ARGON2_MEMORY_DEFAULT,
        .time = ARGON2_TIME_DEFAULT,
        .parallelism = ARGON2_PARALLELISM_DEFAULT,
    };
}

// Validate Argon2 parameters
fn validate_argon2_params(params: *const Argon2Params) bool {
    std.debug.assert(params != null);
    if (params.memory_kb < 8 or params.memory_kb > ARGON2_MAX_MEMORY) {
        return false;
    }
    if (params.time < 1 or params.time > ARGON2_MAX_TIME) {
        return false;
    }
    if (params.parallelism < 1 or params.parallelism > ARGON2_MAX_PARALLELISM) {
        return false;
    }
    std.debug.assert(params.memory_kb >= 8);
    std.debug.assert(params.time >= 1);
    std.debug.assert(params.parallelism >= 1);
    return true;
}

// Blake2b hash for Argon2 (wrapper for std.crypto.hash.blake2.Blake2b)
fn blake2b_hash_for_argon2(
    output_len: u32,
    input: []const u8,
    key: ?[]const u8,
    output: []u8,
) void {
    std.debug.assert(output_len > 0);
    std.debug.assert(output_len <= 64);
    std.debug.assert(input.len > 0);
    std.debug.assert(output.len >= output_len);
    var hasher = std.crypto.hash.blake2.Blake2b(output_len);
    if (key) |k| {
        hasher.update(k);
    }
    hasher.update(input);
    hasher.final(output[0..output_len]);
    std.debug.assert(output.len >= output_len);
}

// Helper: Parse Argon2 hash string format (Phase 2.2 - placeholder)
fn parse_argon2_hash_string(
    hash_string: []const u8,
    params_out: *Argon2Params,
    salt_out: []u8,
    hash_out: []u8,
) bool {
    std.debug.assert(hash_string.len > 0);
    std.debug.assert(hash_string.len <= ARGON2_MAX_HASH_STRING_LEN);
    std.debug.assert(params_out != null);
    std.debug.assert(salt_out.len >= ARGON2_SALT_LEN);
    std.debug.assert(hash_out.len >= ARGON2_HASH_LEN);
    // TODO: Phase 2.2 - Parse hash string format:
    // $argon2id$v=19$m=65536,t=2,p=1$salt$hash
    // Format: $variant$v=version$m=memory,t=time,p=parallelism$salt$hash
    _ = hash_string;
    _ = params_out;
    _ = salt_out;
    _ = hash_out;
    return false;
}

// Hash password with Argon2id (Phase 2.1 - placeholder, full implementation pending)
fn hash_argon2id_static(
    password: []const u8,
    params: *const Argon2Params,
    hash_string_out: []u8,
) u32 {
    std.debug.assert(password.len > 0);
    std.debug.assert(password.len <= MAX_PASSWORD_LEN);
    std.debug.assert(hash_string_out.len >= ARGON2_MAX_HASH_STRING_LEN);
    std.debug.assert(validate_argon2_params(params));
    // TODO: Phase 2.1 - Implement full Argon2id algorithm
    // This is a placeholder. Full implementation will:
    // 1. Generate random salt (ARGON2_SALT_LEN bytes)
    // 2. Run Argon2id core algorithm with params
    // 3. Encode hash string: $argon2id$v=19$m=65536,t=2,p=1$salt$hash
    // For now, return 0 to indicate not implemented
    _ = password;
    _ = params;
    _ = hash_string_out;
    return 0;
}

// Verify password against Argon2id hash (Phase 2.1 - placeholder)
fn verify_argon2id_static(
    password: []const u8,
    stored_hash: []const u8,
) bool {
    std.debug.assert(password.len > 0);
    std.debug.assert(password.len <= MAX_PASSWORD_LEN);
    std.debug.assert(stored_hash.len > 0);
    // TODO: Phase 2.1 - Implement Argon2id verification
    // This is a placeholder. Full implementation will:
    // 1. Parse Argon2 hash string format
    // 2. Extract salt, parameters, and hash
    // 3. Hash password with extracted salt and parameters
    // 4. Compare computed hash with stored hash
    // For now, return false (not implemented)
    _ = password;
    _ = stored_hash;
    return false;
}

// Note: Full Argon2id implementation will be added in Phase 2.1
// The complete Argon2 algorithm is complex and will require:
// - Memory-hard function implementation (RFC 9106 Section 3.2)
// - Block compression algorithm (Blake2b-based)
// - Hash string encoding/decoding (RFC 9106 Section 3.1)
// - Comprehensive testing against RFC 9106 test vectors
// - Performance optimization for RISC-V

