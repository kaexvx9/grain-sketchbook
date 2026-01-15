// C-compatible FFI exports for Grain Carry Core Database Integration
// Grain Style compliant: explicit types, bounded allocations, assertions
//
// Provides C-compatible API for database operations (create, read, update)
// Used by mobile apps (Kotlin/Swift) for user data management

const std = @import("std");
const database_integration = @import("../api/database_integration.zig");
const models = @import("../api/models.zig");

// C-compatible return codes (mapped from DatabaseResult enum)
pub const RESULT_SUCCESS: c_int = 0;
pub const RESULT_NOT_FOUND: c_int = 1;
pub const RESULT_VALIDATION_ERROR: c_int = 2;
pub const RESULT_CONNECTION_ERROR: c_int = 3;
pub const RESULT_INTERNAL_ERROR: c_int = 4;
pub const RESULT_TIMEOUT_ERROR: c_int = 5;
pub const RESULT_RATE_LIMIT_ERROR: c_int = 6;

// Map DatabaseResult to C-compatible return code
fn db_result_to_c_code(result: database_integration.DatabaseResult) c_int {
    return switch (result) {
        .success => RESULT_SUCCESS,
        .not_found => RESULT_NOT_FOUND,
        .validation_error => RESULT_VALIDATION_ERROR,
        .connection_error => RESULT_CONNECTION_ERROR,
        .internal_error => RESULT_INTERNAL_ERROR,
        .timeout_error => RESULT_TIMEOUT_ERROR,
        .rate_limit_error => RESULT_RATE_LIMIT_ERROR,
    };
}

// Export C-compatible user data structure
pub const CUserData = database_integration.UserData;

// Export C-compatible database configuration function
export fn grain_carry_set_database_config(
    base_url_ptr: [*c]const u8,
    base_url_len: u32,
) c_int {
    std.debug.assert(base_url_ptr != null);
    std.debug.assert(base_url_len > 0);
    std.debug.assert(base_url_len <= database_integration.MAX_DB_BASE_URL_LEN);
    
    const base_url = base_url_ptr[0..base_url_len];
    var config = database_integration.DatabaseConfig.init();
    if (!config.set_base_url(base_url)) {
        return RESULT_VALIDATION_ERROR;
    }
    config.enabled = true;
    database_integration.set_database_config(config);
    
    std.debug.assert(config.enabled);
    
    return RESULT_SUCCESS;
}

// Export C-compatible create user function
export fn grain_carry_create_user(
    user_data: *const CUserData,
) c_int {
    std.debug.assert(user_data != null);
    std.debug.assert(user_data.user_id_len > 0);
    std.debug.assert(user_data.user_id_len <= models.MAX_USER_ID_LEN);
    std.debug.assert(user_data.email_len > 0);
    std.debug.assert(user_data.email_len <= models.MAX_EMAIL_LEN);
    
    const result = database_integration.create_user(user_data);
    
    std.debug.assert(@intFromEnum(result) < 7);
    
    return db_result_to_c_code(result);
}

// Export C-compatible get user by ID function
export fn grain_carry_get_user_by_id(
    user_id_ptr: [*c]const u8,
    user_id_len: u32,
    user_out: *CUserData,
) c_int {
    std.debug.assert(user_id_ptr != null);
    std.debug.assert(user_id_len > 0);
    std.debug.assert(user_id_len <= models.MAX_USER_ID_LEN);
    std.debug.assert(user_out != null);
    
    const user_id = user_id_ptr[0..user_id_len];
    const result = database_integration.get_user_by_id(user_id, user_out);
    
    std.debug.assert(user_id.len == user_id_len);
    std.debug.assert(@intFromEnum(result) < 7);
    
    return db_result_to_c_code(result);
}

// Export C-compatible get user by email function
export fn grain_carry_get_user_by_email(
    email_ptr: [*c]const u8,
    email_len: u32,
    user_out: *CUserData,
) c_int {
    std.debug.assert(email_ptr != null);
    std.debug.assert(email_len > 0);
    std.debug.assert(email_len <= models.MAX_EMAIL_LEN);
    std.debug.assert(user_out != null);
    
    const email = email_ptr[0..email_len];
    const result = database_integration.get_user_by_email(email, user_out);
    
    std.debug.assert(email.len == email_len);
    std.debug.assert(@intFromEnum(result) < 7);
    
    return db_result_to_c_code(result);
}

// Export C-compatible update user function
export fn grain_carry_update_user(
    user_id_ptr: [*c]const u8,
    user_id_len: u32,
    user_data: *const CUserData,
) c_int {
    std.debug.assert(user_id_ptr != null);
    std.debug.assert(user_id_len > 0);
    std.debug.assert(user_id_len <= models.MAX_USER_ID_LEN);
    std.debug.assert(user_data != null);
    
    const user_id = user_id_ptr[0..user_id_len];
    const result = database_integration.update_user(user_id, user_data);
    
    std.debug.assert(user_id.len == user_id_len);
    std.debug.assert(@intFromEnum(result) < 7);
    
    return db_result_to_c_code(result);
}

// Export C-compatible initialize user data function
export fn grain_carry_init_user_data(
    user_out: *CUserData,
) c_int {
    std.debug.assert(user_out != null);
    
    user_out.* = database_integration.UserData.init();
    
    std.debug.assert(user_out.user_id_len == 0);
    std.debug.assert(user_out.email_len == 0);
    
    return RESULT_SUCCESS;
}
