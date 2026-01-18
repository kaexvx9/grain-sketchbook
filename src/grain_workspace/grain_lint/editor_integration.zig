//! Grain Style Editor Integration: Vim/Kakoune/Neovim integration
//!
//! Why: Provides editor integration helpers for Vim, Kakoune, and Neovim.
//! Architecture: Editor-specific integration functions.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");

// Editor type enumeration.
pub const EditorType = enum(u8) {
    vim, // Vim editor
    kakoune, // Kakoune editor
    neovim, // Neovim editor
};

/// Generate Vim integration script.
pub fn generate_vim_script(allocator: std.mem.Allocator) ![]const u8 {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const script =
        \\" Grain Style Linter integration for Vim
        \\function! GrainLint()
        \\  let l:file = expand('%:p')
        \\  let l:output = system('grain_lint lint ' . shellescape(l:file))
        \\  echo l:output
        \\endfunction
        \\
        \\" Keybinding
        \\nnoremap <leader>gl :call GrainLint()<CR>
        \\
    ;

    const result = try allocator.dupe(u8, script);
    return result;
}

/// Generate Kakoune integration script.
pub fn generate_kakoune_script(allocator: std.mem.Allocator) ![]const u8 {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const script =
        \\# Grain Style Linter integration for Kakoune
        \\define-command grain-lint %{
        \\  evaluate-commands %sh{
        \\    grain_lint lint "$kak_buffile" | head -20
        \\  }
        \\}
        \\
        \\# Keybinding
        \\map global user <leader>gl ': grain-lint<ret>'
        \\
    ;

    const result = try allocator.dupe(u8, script);
    return result;
}

/// Generate Neovim integration script.
pub fn generate_neovim_script(allocator: std.mem.Allocator) ![]const u8 {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const script =
        \\-- Grain Style Linter integration for Neovim
        \\vim.api.nvim_create_user_command('GrainLint', function()
        \\  local file = vim.fn.expand('%:p')
        \\  vim.fn.jobstart({'grain_lint', 'lint', file}, {
        \\    stdout_buffered = true,
        \\    on_stdout = function(_, data)
        \\      vim.print(data)
        \\    end,
        \\  })
        \\end, {})
        \\
        \\-- Keybinding
        \\vim.keymap.set('n', '<leader>gl', ':GrainLint<CR>')
        \\
    ;

    const result = try allocator.dupe(u8, script);
    return result;
}

/// Generate integration script for specified editor.
pub fn generate_editor_script(
    allocator: std.mem.Allocator,
    editor: EditorType,
) ![]const u8 {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    return switch (editor) {
        .vim => try generate_vim_script(allocator),
        .kakoune => try generate_kakoune_script(allocator),
        .neovim => try generate_neovim_script(allocator),
    };
}
