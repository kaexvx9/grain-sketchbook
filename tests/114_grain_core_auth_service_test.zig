//! Tests for Grain OS Authentication Service
//! Grain Style: grain_case, u32/u64, bounded allocations, assertions

const std = @import("std");
const auth_service = @import("grain_core").auth_service;

test "auth_service_init" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    std.debug.assert(service.secret_len > 0);
    std.debug.assert(service.session_count == 0);
    std.debug.assert(service.otp_count == 0);
    std.debug.assert(service.revoked_count == 0);
}

test "auth_service_generate_access_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var token: [auth_service.MAX_JWT_LEN]u8 = undefined;
    const token_len = service.generate_access_token(user_id, current_time, &token);
    std.debug.assert(token_len > 0);
    std.debug.assert(token_len <= auth_service.MAX_JWT_LEN);
}

test "auth_service_validate_jwt_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var token: [auth_service.MAX_JWT_LEN]u8 = undefined;
    const token_len = service.generate_access_token(user_id, current_time, &token);
    std.debug.assert(token_len > 0);
    var claims: auth_service.JwtClaims = undefined;
    const is_valid = service.validate_jwt_token(
        token[0..token_len],
        current_time,
        &claims,
    );
    std.debug.assert(is_valid);
    std.debug.assert(claims.user_id_len > 0);
    std.debug.assert(claims.exp > current_time);
}

test "auth_service_revoke_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var token: [auth_service.MAX_JWT_LEN]u8 = undefined;
    const token_len = service.generate_access_token(user_id, current_time, &token);
    std.debug.assert(token_len > 0);
    const revoked = service.revoke_token(token[0..token_len]);
    std.debug.assert(revoked);
    std.debug.assert(service.revoked_count == 1);
    var claims: auth_service.JwtClaims = undefined;
    const is_valid = service.validate_jwt_token(
        token[0..token_len],
        current_time,
        &claims,
    );
    std.debug.assert(!is_valid);
}

test "auth_service_hash_password" {
    const password = "test_password_123";
    var hash: [auth_service.HASH_OUTPUT_LEN]u8 = undefined;
    auth_service.AuthService.hash_password_static(password, &hash);
    std.debug.assert(hash.len == auth_service.HASH_OUTPUT_LEN);
}

test "auth_service_verify_password" {
    const password = "test_password_123";
    var hash: [auth_service.HASH_OUTPUT_LEN]u8 = undefined;
    auth_service.AuthService.hash_password_static(password, &hash);
    const is_valid = auth_service.AuthService.verify_password_static(password, &hash);
    std.debug.assert(is_valid);
    const wrong_password = "wrong_password";
    const is_invalid = auth_service.AuthService.verify_password_static(wrong_password, &hash);
    std.debug.assert(!is_invalid);
}

test "auth_service_create_session" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var session: auth_service.Session = undefined;
    const created = service.create_session(user_id, current_time, &session);
    std.debug.assert(created);
    std.debug.assert(service.session_count == 1);
    std.debug.assert(session.user_id_len > 0);
    std.debug.assert(session.is_active);
    std.debug.assert(session.expires_at > current_time);
}

test "auth_service_validate_session" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var session: auth_service.Session = undefined;
    const created = service.create_session(user_id, current_time, &session);
    std.debug.assert(created);
    const session_id = session.session_id[0..session.session_id_len];
    var validated_session: auth_service.Session = undefined;
    const is_valid = service.validate_session(session_id, current_time, &validated_session);
    std.debug.assert(is_valid);
    std.debug.assert(validated_session.user_id_len > 0);
}

test "auth_service_revoke_session" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const current_time: u64 = 1000000;
    var session: auth_service.Session = undefined;
    const created = service.create_session(user_id, current_time, &session);
    std.debug.assert(created);
    const session_id = session.session_id[0..session.session_id_len];
    const revoked = service.revoke_session(session_id);
    std.debug.assert(revoked);
    const is_valid = service.validate_session(session_id, current_time, null);
    std.debug.assert(!is_valid);
}

test "auth_service_generate_otp" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const email = "test@example.com";
    const current_time: u64 = 1000000;
    var otp: auth_service.Otp = undefined;
    const generated = service.generate_otp(email, current_time, &otp);
    std.debug.assert(generated);
    std.debug.assert(service.otp_count == 1);
    std.debug.assert(otp.code_len > 0);
    std.debug.assert(otp.email_len > 0);
    std.debug.assert(!otp.is_used);
    std.debug.assert(otp.expires_at > current_time);
}

test "auth_service_validate_otp" {
    const secret = "test_secret_key_for_jwt_signing";
    var service = auth_service.AuthService.init(secret);
    const email = "test@example.com";
    const current_time: u64 = 1000000;
    var otp: auth_service.Otp = undefined;
    const generated = service.generate_otp(email, current_time, &otp);
    std.debug.assert(generated);
    const code = otp.code[0..otp.code_len];
    const is_valid = service.validate_otp(email, code, current_time);
    std.debug.assert(is_valid);
    const is_invalid = service.validate_otp(email, code, current_time);
    std.debug.assert(!is_invalid);
}

test "auth_service_generate_totp" {
    const secret = "test_secret_for_totp";
    const timestamp: u64 = 1000000;
    const code = auth_service.AuthService.generate_totp(secret, timestamp);
    std.debug.assert(code < 1000000);
    std.debug.assert(code >= 0);
}

test "auth_service_validate_totp" {
    const secret = "test_secret_for_totp";
    const timestamp: u64 = 1000000;
    const code = auth_service.AuthService.generate_totp(secret, timestamp);
    const is_valid = auth_service.AuthService.validate_totp(secret, code, timestamp);
    std.debug.assert(is_valid);
    const wrong_code: u32 = 123456;
    const is_invalid = auth_service.AuthService.validate_totp(secret, wrong_code, timestamp);
    std.debug.assert(!is_invalid);
}

// ============================================================================
// Argon2 Password Hashing Tests (Phase 2.3)
// ============================================================================

test "auth_service_detect_hash_format_sha256" {
    var hash: [auth_service.HASH_OUTPUT_LEN]u8 = undefined;
    auth_service.AuthService.hash_password_static("test", &hash);
    const format = auth_service.AuthService.detect_hash_format(&hash);
    std.debug.assert(format == auth_service.HashFormat.sha256);
    std.debug.assert(hash.len == auth_service.HASH_OUTPUT_LEN);
}

test "auth_service_get_default_argon2_params" {
    const params = auth_service.get_default_argon2_params();
    std.debug.assert(params.memory_kb == auth_service.ARGON2_MEMORY_DEFAULT);
    std.debug.assert(params.time == auth_service.ARGON2_TIME_DEFAULT);
    std.debug.assert(params.parallelism == auth_service.ARGON2_PARALLELISM_DEFAULT);
}

test "auth_service_argon2_hash_password" {
    const password = "test_password_argon2";
    const params = auth_service.get_default_argon2_params();
    var hash_string: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const hash_len = auth_service.hash_argon2id_static(password, &params, &hash_string);
    std.debug.assert(hash_len > 0);
    std.debug.assert(hash_len <= auth_service.ARGON2_MAX_HASH_STRING_LEN);
    std.debug.assert(hash_string[0] == '$');
}

test "auth_service_argon2_verify_password" {
    const password = "test_password_argon2";
    const params = auth_service.get_default_argon2_params();
    var hash_string: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const hash_len = auth_service.hash_argon2id_static(password, &params, &hash_string);
    std.debug.assert(hash_len > 0);
    const is_valid = auth_service.verify_argon2id_static(
        password,
        hash_string[0..hash_len],
    );
    std.debug.assert(is_valid);
    const wrong_password = "wrong_password";
    const is_invalid = auth_service.verify_argon2id_static(
        wrong_password,
        hash_string[0..hash_len],
    );
    std.debug.assert(!is_invalid);
}

test "auth_service_argon2_hash_format_detection" {
    const password = "test_password";
    const params = auth_service.get_default_argon2_params();
    var hash_string: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const hash_len = auth_service.hash_argon2id_static(password, &params, &hash_string);
    std.debug.assert(hash_len > 0);
    const format = auth_service.AuthService.detect_hash_format(hash_string[0..hash_len]);
    std.debug.assert(format == auth_service.HashFormat.argon2id);
}

test "auth_service_verify_password_both_formats" {
    const password = "test_password_migration";
    var sha256_hash: [auth_service.HASH_OUTPUT_LEN]u8 = undefined;
    auth_service.AuthService.hash_password_static(password, &sha256_hash);
    const sha256_valid = auth_service.AuthService.verify_password_static(
        password,
        &sha256_hash,
    );
    std.debug.assert(sha256_valid);
    const params = auth_service.get_default_argon2_params();
    var argon2_hash: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const argon2_len = auth_service.hash_argon2id_static(password, &params, &argon2_hash);
    std.debug.assert(argon2_len > 0);
    const argon2_valid = auth_service.AuthService.verify_password_static(
        password,
        argon2_hash[0..argon2_len],
    );
    std.debug.assert(argon2_valid);
}

test "auth_service_argon2_parse_hash_string" {
    const password = "test_parse";
    const params = auth_service.get_default_argon2_params();
    var hash_string: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const hash_len = auth_service.hash_argon2id_static(password, &params, &hash_string);
    std.debug.assert(hash_len > 0);
    var parsed_params: auth_service.Argon2Params = undefined;
    var salt: [auth_service.ARGON2_SALT_LEN]u8 = undefined;
    var hash: [auth_service.ARGON2_HASH_LEN]u8 = undefined;
    const parsed = auth_service.parse_argon2_hash_string(
        hash_string[0..hash_len],
        &parsed_params,
        &salt,
        &hash,
    );
    std.debug.assert(parsed);
    std.debug.assert(parsed_params.memory_kb == params.memory_kb);
    std.debug.assert(parsed_params.time == params.time);
    std.debug.assert(parsed_params.parallelism == params.parallelism);
}

test "auth_service_argon2_hash_different_salts" {
    const password = "test_salt_variation";
    const params = auth_service.get_default_argon2_params();
    var hash1: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    var hash2: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const len1 = auth_service.hash_argon2id_static(password, &params, &hash1);
    const len2 = auth_service.hash_argon2id_static(password, &params, &hash2);
    std.debug.assert(len1 > 0);
    std.debug.assert(len2 > 0);
    const hashes_differ = !std.mem.eql(
        u8,
        hash1[0..len1],
        hash2[0..len2],
    );
    std.debug.assert(hashes_differ);
    const valid1 = auth_service.verify_argon2id_static(password, hash1[0..len1]);
    const valid2 = auth_service.verify_argon2id_static(password, hash2[0..len2]);
    std.debug.assert(valid1);
    std.debug.assert(valid2);
}

test "auth_service_argon2_invalid_hash_string" {
    const password = "test_invalid";
    const invalid_hash = "not_a_valid_argon2_hash";
    const is_valid = auth_service.verify_argon2id_static(password, invalid_hash);
    std.debug.assert(!is_valid);
}

test "auth_service_argon2_custom_parameters" {
    const password = "test_custom_params";
    var custom_params = auth_service.Argon2Params{
        .memory_kb = 32768,
        .time = 3,
        .parallelism = 2,
    };
    var hash_string: [auth_service.ARGON2_MAX_HASH_STRING_LEN]u8 = undefined;
    const hash_len = auth_service.hash_argon2id_static(password, &custom_params, &hash_string);
    std.debug.assert(hash_len > 0);
    var parsed_params: auth_service.Argon2Params = undefined;
    var salt: [auth_service.ARGON2_SALT_LEN]u8 = undefined;
    var hash: [auth_service.ARGON2_HASH_LEN]u8 = undefined;
    const parsed = auth_service.parse_argon2_hash_string(
        hash_string[0..hash_len],
        &parsed_params,
        &salt,
        &hash,
    );
    std.debug.assert(parsed);
    std.debug.assert(parsed_params.memory_kb == custom_params.memory_kb);
    std.debug.assert(parsed_params.time == custom_params.time);
    std.debug.assert(parsed_params.parallelism == custom_params.parallelism);
    const is_valid = auth_service.verify_argon2id_static(
        password,
        hash_string[0..hash_len],
    );
    std.debug.assert(is_valid);
}

// ============================================================================
// API Key Management Tests (Phase 3)
// ============================================================================

test "auth_service_generate_api_key" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_live";
    const scopes = [_]auth_service.ApiKeyScope{
        auth_service.ApiKeyScope.read,
        auth_service.ApiKeyScope.write,
    };
    const current_time: u64 = 1000000;
    const expiry: u64 = 31536000; // 1 year
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    std.debug.assert(key_len <= auth_service.MAX_API_KEY_LEN);
    std.debug.assert(service.api_key_count == 1);
    var i: u32 = 0;
    while (i < prefix.len and i < key_len) : (i += 1) {
        std.debug.assert(api_key[i] == prefix[i]);
    }
}

test "auth_service_validate_api_key" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.read };
    const current_time: u64 = 1000000;
    const expiry: u64 = 3600; // 1 hour
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    var metadata: auth_service.ApiKey = undefined;
    const is_valid = service.validate_api_key(
        api_key[0..key_len],
        current_time,
        &metadata,
    );
    std.debug.assert(is_valid);
    std.debug.assert(metadata.user_id_len > 0);
    std.debug.assert(metadata.is_active);
    std.debug.assert(metadata.scope_count == 1);
}

test "auth_service_validate_api_key_wrong_key" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const wrong_key = "wrong_api_key_string";
    const current_time: u64 = 1000000;
    const is_valid = service.validate_api_key(wrong_key, current_time, null);
    std.debug.assert(!is_valid);
}

test "auth_service_validate_api_key_expired" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.read };
    const created_time: u64 = 1000000;
    const expiry: u64 = 3600; // 1 hour
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        created_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    const expired_time = created_time + expiry + 1;
    const is_valid = service.validate_api_key(
        api_key[0..key_len],
        expired_time,
        null,
    );
    std.debug.assert(!is_valid);
}

test "auth_service_revoke_api_key" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.read };
    const current_time: u64 = 1000000;
    const expiry: u64 = 3600;
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    const revoked = service.revoke_api_key(api_key[0..key_len]);
    std.debug.assert(revoked);
    std.debug.assert(service.revoked_api_key_count == 1);
    const is_valid = service.validate_api_key(
        api_key[0..key_len],
        current_time,
        null,
    );
    std.debug.assert(!is_valid);
}

test "auth_service_api_key_has_scope" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{
        auth_service.ApiKeyScope.read,
        auth_service.ApiKeyScope.write,
    };
    const current_time: u64 = 1000000;
    const expiry: u64 = 3600;
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    var metadata: auth_service.ApiKey = undefined;
    const is_valid = service.validate_api_key(
        api_key[0..key_len],
        current_time,
        &metadata,
    );
    std.debug.assert(is_valid);
    const has_read = auth_service.api_key_has_scope(&metadata, auth_service.ApiKeyScope.read);
    const has_write = auth_service.api_key_has_scope(&metadata, auth_service.ApiKeyScope.write);
    const has_admin = auth_service.api_key_has_scope(&metadata, auth_service.ApiKeyScope.admin);
    std.debug.assert(has_read);
    std.debug.assert(has_write);
    std.debug.assert(!has_admin);
}

test "auth_service_api_key_admin_scope" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.admin };
    const current_time: u64 = 1000000;
    const expiry: u64 = 3600;
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    var metadata: auth_service.ApiKey = undefined;
    const is_valid = service.validate_api_key(
        api_key[0..key_len],
        current_time,
        &metadata,
    );
    std.debug.assert(is_valid);
    const has_read = auth_service.api_key_has_scope(&metadata, auth_service.ApiKeyScope.read);
    const has_write = auth_service.api_key_has_scope(&metadata, auth_service.ApiKeyScope.write);
    std.debug.assert(has_read);
    std.debug.assert(has_write);
}

test "auth_service_api_key_multiple_keys" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.read };
    const current_time: u64 = 1000000;
    const expiry: u64 = 3600;
    var api_key1: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    var api_key2: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const len1 = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key1,
    );
    const len2 = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        current_time,
        &api_key2,
    );
    std.debug.assert(len1 > 0);
    std.debug.assert(len2 > 0);
    std.debug.assert(service.api_key_count == 2);
    const keys_differ = !std.mem.eql(u8, api_key1[0..len1], api_key2[0..len2]);
    std.debug.assert(keys_differ);
    const valid1 = service.validate_api_key(api_key1[0..len1], current_time, null);
    const valid2 = service.validate_api_key(api_key2[0..len2], current_time, null);
    std.debug.assert(valid1);
    std.debug.assert(valid2);
}

test "auth_service_api_key_last_used_tracking" {
    const secret = "test_secret_key_for_api_keys";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const prefix = "grain_test";
    const scopes = [_]auth_service.ApiKeyScope{ auth_service.ApiKeyScope.read };
    const created_time: u64 = 1000000;
    const expiry: u64 = 3600;
    var api_key: [auth_service.MAX_API_KEY_LEN]u8 = undefined;
    const key_len = service.generate_api_key(
        user_id,
        prefix,
        &scopes,
        expiry,
        created_time,
        &api_key,
    );
    std.debug.assert(key_len > 0);
    var metadata1: auth_service.ApiKey = undefined;
    const first_use = created_time + 100;
    service.validate_api_key(api_key[0..key_len], first_use, &metadata1);
    std.debug.assert(metadata1.last_used_at == first_use);
    var metadata2: auth_service.ApiKey = undefined;
    const second_use = created_time + 200;
    service.validate_api_key(api_key[0..key_len], second_use, &metadata2);
    std.debug.assert(metadata2.last_used_at == second_use);
}

// ============================================================================
// RBAC Tests (Phase 5)
// ============================================================================

test "auth_service_create_role" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const role_name = "admin";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    std.debug.assert(role_id.? == 1);
    std.debug.assert(service.role_count == 1);
    std.debug.assert(service.next_role_id == 2);
}

test "auth_service_create_role_with_parent" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const parent_name = "user";
    const child_name = "editor";
    const parent_id = service.create_role(parent_name, null);
    std.debug.assert(parent_id != null);
    const child_id = service.create_role(child_name, parent_id);
    std.debug.assert(child_id != null);
    std.debug.assert(service.role_count == 2);
    const child_role = service.get_role_by_id(child_id.?);
    std.debug.assert(child_role != null);
    std.debug.assert(child_role.?.parent_role_id == parent_id);
}

test "auth_service_add_permission_to_role" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const role_name = "editor";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    const perm_name = "edit_articles";
    const resource = "articles";
    const action = auth_service.PermissionAction.write;
    const added = service.add_permission_to_role(role_id.?, perm_name, resource, action);
    std.debug.assert(added);
    const role = service.get_role_by_id(role_id.?);
    std.debug.assert(role != null);
    std.debug.assert(role.?.permission_count == 1);
    std.debug.assert(role.?.permissions[0].action == action);
}

test "auth_service_user_has_permission" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const role_name = "editor";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    const perm_name = "edit_articles";
    const resource = "articles";
    const action = auth_service.PermissionAction.write;
    service.add_permission_to_role(role_id.?, perm_name, resource, action);
    var claims: auth_service.JwtClaims = undefined;
    claims.user_id_len = 0;
    claims.exp = 1000000;
    claims.iat = 1000000;
    claims.token_type = auth_service.TokenType.access;
    claims.role_count = 1;
    claims.roles[0] = role_id.?;
    const has_perm = service.user_has_permission(&claims, resource, action);
    std.debug.assert(has_perm);
    const delete_action = auth_service.PermissionAction.delete;
    const no_perm = service.user_has_permission(&claims, resource, delete_action);
    std.debug.assert(!no_perm);
}

test "auth_service_admin_permission_grants_all" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const role_name = "admin";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    const perm_name = "admin_all";
    const resource = "all";
    const action = auth_service.PermissionAction.admin;
    service.add_permission_to_role(role_id.?, perm_name, resource, action);
    var claims: auth_service.JwtClaims = undefined;
    claims.user_id_len = 0;
    claims.exp = 1000000;
    claims.iat = 1000000;
    claims.token_type = auth_service.TokenType.access;
    claims.role_count = 1;
    claims.roles[0] = role_id.?;
    const read_action = auth_service.PermissionAction.read;
    const write_action = auth_service.PermissionAction.write;
    const delete_action_admin = auth_service.PermissionAction.delete;
    const has_read = service.user_has_permission(&claims, "articles", read_action);
    const has_write = service.user_has_permission(&claims, "articles", write_action);
    const has_delete = service.user_has_permission(&claims, "articles", delete_action_admin);
    std.debug.assert(has_read);
    std.debug.assert(has_write);
    std.debug.assert(has_delete);
}

test "auth_service_assign_role_to_user" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const role_name = "editor";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    var current_roles: [auth_service.MAX_ROLES_PER_USER]u32 = undefined;
    var roles_out: [auth_service.MAX_ROLES_PER_USER]u32 = undefined;
    const new_count = service.assign_role_to_user(
        user_id,
        role_id.?,
        &current_roles,
        0,
        &roles_out,
    );
    std.debug.assert(new_count == 1);
    std.debug.assert(roles_out[0] == role_id.?);
    const duplicate_count = service.assign_role_to_user(
        user_id,
        role_id.?,
        &current_roles,
        0,
        &roles_out,
    );
    std.debug.assert(duplicate_count == 1);
}

test "auth_service_multiple_roles_per_user" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const user_id = "user123";
    const role1_name = "editor";
    const role2_name = "reviewer";
    const role1_id = service.create_role(role1_name, null);
    const role2_id = service.create_role(role2_name, null);
    std.debug.assert(role1_id != null);
    std.debug.assert(role2_id != null);
    var current_roles: [auth_service.MAX_ROLES_PER_USER]u32 = undefined;
    var roles_out: [auth_service.MAX_ROLES_PER_USER]u32 = undefined;
    const count1 = service.assign_role_to_user(user_id, role1_id.?, &current_roles, 0, &roles_out);
    std.debug.assert(count1 == 1);
    const count2 = service.assign_role_to_user(user_id, role2_id.?, roles_out, count1, &roles_out);
    std.debug.assert(count2 == 2);
    std.debug.assert(roles_out[0] == role1_id.?);
    std.debug.assert(roles_out[1] == role2_id.?);
}

test "auth_service_inactive_role_no_permission" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const role_name = "editor";
    const role_id = service.create_role(role_name, null);
    std.debug.assert(role_id != null);
    const perm_name = "edit_articles";
    const resource = "articles";
    const action = auth_service.PermissionAction.write;
    service.add_permission_to_role(role_id.?, perm_name, resource, action);
    var role = service.get_role_by_id(role_id.?);
    std.debug.assert(role != null);
    role.?.is_active = false;
    var claims: auth_service.JwtClaims = undefined;
    claims.user_id_len = 0;
    claims.exp = 1000000;
    claims.iat = 1000000;
    claims.token_type = auth_service.TokenType.access;
    claims.role_count = 1;
    claims.roles[0] = role_id.?;
    const has_perm = service.user_has_permission(&claims, resource, action);
    std.debug.assert(!has_perm);
}

test "auth_service_role_hierarchy" {
    const secret = "test_secret_for_rbac";
    var service = auth_service.AuthService.init(secret);
    const parent_name = "user";
    const child_name = "editor";
    const parent_id = service.create_role(parent_name, null);
    std.debug.assert(parent_id != null);
    const child_id = service.create_role(child_name, parent_id);
    std.debug.assert(child_id != null);
    const parent_perm = "view_articles";
    const child_perm = "edit_articles";
    const read_perm = auth_service.PermissionAction.read;
    const write_perm = auth_service.PermissionAction.write;
    service.add_permission_to_role(parent_id.?, parent_perm, "articles", read_perm);
    service.add_permission_to_role(child_id.?, child_perm, "articles", write_perm);
    var claims: auth_service.JwtClaims = undefined;
    claims.user_id_len = 0;
    claims.exp = 1000000;
    claims.iat = 1000000;
    claims.token_type = auth_service.TokenType.access;
    claims.role_count = 1;
    claims.roles[0] = child_id.?;
    const write_action_check = auth_service.PermissionAction.write;
    const has_child_write = service.user_has_permission(&claims, "articles", write_action_check);
    std.debug.assert(has_child_write);
}

// ============================================================================
// Security Hardening Tests (Phase 6)
// ============================================================================

test "auth_service_generate_csrf_token" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const current_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = service.generate_csrf_token(session_id, current_time, &token);
    std.debug.assert(token_len > 0);
    std.debug.assert(token_len <= auth_service.CSRF_TOKEN_STRING_LEN);
    std.debug.assert(service.csrf_token_count == 1);
}

test "auth_service_validate_csrf_token" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const current_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = service.generate_csrf_token(session_id, current_time, &token);
    std.debug.assert(token_len > 0);
    const is_valid = service.validate_csrf_token(
        token[0..token_len],
        session_id,
        current_time,
    );
    std.debug.assert(is_valid);
    const is_invalid = service.validate_csrf_token(
        token[0..token_len],
        session_id,
        current_time,
    );
    std.debug.assert(!is_invalid);
}

test "auth_service_validate_csrf_token_wrong_session" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const wrong_session = "session456";
    const current_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = service.generate_csrf_token(session_id, current_time, &token);
    std.debug.assert(token_len > 0);
    const is_valid = service.validate_csrf_token(
        token[0..token_len],
        wrong_session,
        current_time,
    );
    std.debug.assert(!is_valid);
}

test "auth_service_validate_csrf_token_expired" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const created_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = service.generate_csrf_token(session_id, created_time, &token);
    std.debug.assert(token_len > 0);
    const expired_time = created_time + auth_service.CSRF_TOKEN_EXPIRY + 1;
    const is_valid = service.validate_csrf_token(
        token[0..token_len],
        session_id,
        expired_time,
    );
    std.debug.assert(!is_valid);
}

test "auth_service_check_rate_limit" {
    const secret = "test_secret_for_rate_limit";
    var service = auth_service.AuthService.init(secret);
    const identifier = "user123";
    const current_time: u64 = 1000000;
    const limit: u32 = 5;
    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        const allowed = service.check_rate_limit(identifier, current_time, limit);
        std.debug.assert(allowed);
    }
    const exceeded = service.check_rate_limit(identifier, current_time, limit);
    std.debug.assert(!exceeded);
}

test "auth_service_rate_limit_new_window" {
    const secret = "test_secret_for_rate_limit";
    var service = auth_service.AuthService.init(secret);
    const identifier = "user123";
    const window1_time: u64 = 1000000;
    const window2_time: u64 = 1000000 + auth_service.RATE_LIMIT_WINDOW;
    const limit: u32 = 5;
    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        const allowed = service.check_rate_limit(identifier, window1_time, limit);
        std.debug.assert(allowed);
    }
    const exceeded = service.check_rate_limit(identifier, window1_time, limit);
    std.debug.assert(!exceeded);
    const new_window_allowed = service.check_rate_limit(identifier, window2_time, limit);
    std.debug.assert(new_window_allowed);
}

test "auth_service_cleanup_expired_csrf_tokens" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const created_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    service.generate_csrf_token(session_id, created_time, &token);
    std.debug.assert(service.csrf_token_count == 1);
    const cleanup_time = created_time + auth_service.CSRF_TOKEN_EXPIRY + 1;
    service.cleanup_expired_csrf_tokens(cleanup_time);
    std.debug.assert(service.csrf_token_count == 0);
}

test "auth_service_cleanup_expired_rate_limits" {
    const secret = "test_secret_for_rate_limit";
    var service = auth_service.AuthService.init(secret);
    const identifier = "user123";
    const window1_time: u64 = 1000000;
    const limit: u32 = 5;
    service.check_rate_limit(identifier, window1_time, limit);
    std.debug.assert(service.rate_limit_count == 1);
    const cleanup_time = window1_time + auth_service.RATE_LIMIT_WINDOW + 1;
    service.cleanup_expired_rate_limits(cleanup_time);
    std.debug.assert(service.rate_limit_count == 0);
}

test "auth_service_csrf_token_single_use" {
    const secret = "test_secret_for_csrf";
    var service = auth_service.AuthService.init(secret);
    const session_id = "session123";
    const current_time: u64 = 1000000;
    var token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = service.generate_csrf_token(session_id, current_time, &token);
    std.debug.assert(token_len > 0);
    const first_use = service.validate_csrf_token(
        token[0..token_len],
        session_id,
        current_time,
    );
    std.debug.assert(first_use);
    const second_use = service.validate_csrf_token(
        token[0..token_len],
        session_id,
        current_time,
    );
    std.debug.assert(!second_use);
}

