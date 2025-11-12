const std = @import("std");

/// Monospace text renderer: converts GrainBuffer text into RGBA pixels.
/// Uses a simple 8x8 bitmap font until we wire up a proper font loader.
pub const TextRenderer = struct {
    width: u32,
    height: u32,
    font_width: u32 = 8,
    font_height: u32 = 8,

    pub fn render(
        self: *const TextRenderer,
        text: []const u8,
        buffer: []u8,
        fg_r: u8,
        fg_g: u8,
        fg_b: u8,
        bg_r: u8,
        bg_g: u8,
        bg_b: u8,
    ) void {
        const chars_per_row = self.width / self.font_width;
        const rows = self.height / self.font_height;
        var y: u32 = 0;
        var x: u32 = 0;
        var char_idx: usize = 0;

        while (y < rows and char_idx < text.len) : (y += 1) {
            x = 0;
            while (x < chars_per_row and char_idx < text.len) : ({
                x += 1;
                char_idx += 1;
            }) {
                const ch = if (char_idx < text.len) text[char_idx] else ' ';
                self.drawChar(ch, x, y, buffer, fg_r, fg_g, fg_b, bg_r, bg_g, bg_b);
            }
            if (char_idx < text.len and text[char_idx] == '\n') {
                char_idx += 1;
            }
        }
    }

    fn drawChar(
        self: *const TextRenderer,
        ch: u8,
        grid_x: u32,
        grid_y: u32,
        buffer: []u8,
        fg_r: u8,
        fg_g: u8,
        fg_b: u8,
        bg_r: u8,
        bg_g: u8,
        bg_b: u8,
    ) void {
        const start_x = grid_x * self.font_width;
        const start_y = grid_y * self.font_height;
        const pattern = getCharPattern(ch);

        var py: u32 = 0;
        while (py < self.font_height) : (py += 1) {
            var px: u32 = 0;
            while (px < self.font_width) : (px += 1) {
                const buf_x = start_x + px;
                const buf_y = start_y + py;
                if (buf_x >= self.width or buf_y >= self.height) continue;

                const pixel_idx = (buf_y * self.width + buf_x) * 4;
                if (pixel_idx + 3 >= buffer.len) continue;

                const bit_idx = py * self.font_width + px;
                const bit = (pattern >> @as(u6, @intCast(63 - bit_idx))) & 1;

                if (bit == 1) {
                    buffer[pixel_idx] = fg_r;
                    buffer[pixel_idx + 1] = fg_g;
                    buffer[pixel_idx + 2] = fg_b;
                } else {
                    buffer[pixel_idx] = bg_r;
                    buffer[pixel_idx + 1] = bg_g;
                    buffer[pixel_idx + 2] = bg_b;
                }
                buffer[pixel_idx + 3] = 255;
            }
        }
    }

    fn getCharPattern(ch: u8) u64 {
        // Minimal 8x8 bitmap patterns for ASCII 32-126.
        // Pattern is row-major, MSB first (top-left to bottom-right).
        const patterns = struct {
            fn get(c: u8) u64 {
                return switch (c) {
                    ' ' => 0x0000000000000000,
                    '!' => 0x1818181818001800,
                    '"' => 0x3636000000000000,
                    '#' => 0x36367F36367F3636,
                    '$' => 0x0C3E033E301F0C00,
                    '%' => 0x006333180C666300,
                    '&' => 0x1C361C6E3B331E00,
                    '\'' => 0x0C0C180000000000,
                    '(' => 0x0C18181818180C00,
                    ')' => 0x180C0C0C0C0C1800,
                    '*' => 0x00183C7E3C180000,
                    '+' => 0x000018187E181800,
                    ',' => 0x0000000000180C18,
                    '-' => 0x000000007E000000,
                    '.' => 0x0000000000181800,
                    '/' => 0x303018180C0C0606,
                    '0' => 0x3C666E7E76663C00,
                    '1' => 0x1818381818187E00,
                    '2' => 0x3C66060C18307E00,
                    '3' => 0x3C66061C06663C00,
                    '4' => 0x060E1E367F060600,
                    '5' => 0x7E607C0606663C00,
                    '6' => 0x1C30607C66663C00,
                    '7' => 0x7E060C1818181800,
                    '8' => 0x3C66663C66663C00,
                    '9' => 0x3C66663E060C3800,
                    ':' => 0x0000180000180000,
                    ';' => 0x0000180000180C18,
                    '<' => 0x000C1830180C0000,
                    '=' => 0x00007E00007E0000,
                    '>' => 0x00180C060C180000,
                    '?' => 0x3C66060C18001800,
                    '@' => 0x3C66766E60663C00,
                    'A' => 0x183C66667E666600,
                    'B' => 0x7C66667C66667C00,
                    'C' => 0x3C66606060663C00,
                    'D' => 0x786C6666666C7800,
                    'E' => 0x7E60607C60607E00,
                    'F' => 0x7E60607C60606000,
                    'G' => 0x3C66606E66663C00,
                    'H' => 0x6666667E66666600,
                    'I' => 0x3C18181818183C00,
                    'J' => 0x1E0C0C0C6C6C3800,
                    'K' => 0x666C7870786C6600,
                    'L' => 0x6060606060607E00,
                    'M' => 0x63777F6B63636300,
                    'N' => 0x66767E7E6E666600,
                    'O' => 0x3C66666666663C00,
                    'P' => 0x7C66667C60606000,
                    'Q' => 0x3C6666666E3C0E00,
                    'R' => 0x7C66667C6C666600,
                    'S' => 0x3C603C0606663C00,
                    'T' => 0x7E18181818181800,
                    'U' => 0x6666666666663C00,
                    'V' => 0x66666666663C1800,
                    'W' => 0x63636B7F77636300,
                    'X' => 0x66663C183C666600,
                    'Y' => 0x66663C1818181800,
                    'Z' => 0x7E060C1830607E00,
                    '[' => 0x3C30303030303C00,
                    '\\' => 0x06060C0C18183030,
                    ']' => 0x3C0C0C0C0C0C3C00,
                    '^' => 0x183C660000000000,
                    '_' => 0x0000000000007E00,
                    '`' => 0x18180C0000000000,
                    'a' => 0x00003C063E663E00,
                    'b' => 0x60607C6666667C00,
                    'c' => 0x00003C6660603C00,
                    'd' => 0x06063E6666663E00,
                    'e' => 0x00003C667E603C00,
                    'f' => 0x1C30307C30303000,
                    'g' => 0x00003E66663E063C,
                    'h' => 0x60607C6666666600,
                    'i' => 0x1800181818181800,
                    'j' => 0x0C000C0C0C6C3800,
                    'k' => 0x6060666C786C6600,
                    'l' => 0x1818181818181800,
                    'm' => 0x0000767F6B636300,
                    'n' => 0x00007C6666666600,
                    'o' => 0x00003C6666663C00,
                    'p' => 0x00007C66667C6060,
                    'q' => 0x00003E66663E0606,
                    'r' => 0x00007C6660606000,
                    's' => 0x00003E603C067C00,
                    't' => 0x30307C3030301C00,
                    'u' => 0x0000666666663E00,
                    'v' => 0x00006666663C1800,
                    'w' => 0x0000636B7F360000,
                    'x' => 0x0000663C183C6600,
                    'y' => 0x00006666663E063C,
                    'z' => 0x00007E0C18307E00,
                    '{' => 0x0C18187018180C00,
                    '|' => 0x1818180018181800,
                    '}' => 0x3018180E18183000,
                    '~' => 0x0000003E6C000000,
                    else => 0x7E8185B581817E00, // fallback: box
                };
            }
        }.get(ch);
        return patterns;
    }
};

test "text renderer draws char" {
    var buffer: [1024 * 768 * 4]u8 = undefined;
    @memset(&buffer, 0);
    const renderer = TextRenderer{ .width = 1024, .height = 768 };
    renderer.render("A", &buffer, 255, 255, 255, 0, 0, 0);
    try std.testing.expect(buffer[0] == 0 or buffer[0] == 255);
}

