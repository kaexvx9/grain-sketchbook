// Grainscript Shell UI Example
// Why: Demonstrate kernel UI integration with a basic REPL shell.
// See: docs/rye/0007-basin-kernel-boot-roadmap.md Phase 5.4

// Check if UI is available
let ui_ready = ui_available()
if !ui_ready {
    echo "UI not available, falling back to text mode"
}

// Create main window
let window = ui_create_window()
if window == null {
    echo "Failed to create window"
    exit 1
}

// Add output list for command history and results
let output = ui_add_list(window)

// Add input field for commands
let input = ui_add_input(window, "grainscript> ")

// Display welcome message
ui_add_label(output, "Grainscript Shell v0.1")
ui_add_label(output, "Type 'help' for available commands")
ui_add_label(output, "")

// Command history
let history_count = 0
let MAX_HISTORY = 100

// Main event loop
let running = true
while running {
    // Poll for events
    let event = ui_poll_event()
    
    if event != null {
        // Check for Enter key (submit command)
        if event == 13 {
            // Get command text
            let command = ui_get_text(input)
            
            // Add to output
            ui_add_label(output, "> " + command)
            
            // Process command
            if command == "exit" || command == "quit" {
                running = false
            } else if command == "help" {
                ui_add_label(output, "Commands:")
                ui_add_label(output, "  help  - Show this message")
                ui_add_label(output, "  clear - Clear output")
                ui_add_label(output, "  exit  - Exit shell")
                ui_add_label(output, "  echo <text> - Print text")
            } else if command == "clear" {
                // Clear output (TODO: implement in ui_builtins)
                ui_add_label(output, "--- cleared ---")
            } else if len(command) > 0 {
                // Try to evaluate as expression
                let result = eval(command)
                if result != null {
                    ui_add_label(output, "= " + str(result))
                }
            }
            
            // Clear input
            ui_set_text(input, "")
            
            // Update history
            history_count = history_count + 1
        }
    }
    
    // Yield to scheduler (cooperative multitasking)
    yield
}

// Cleanup
ui_add_label(output, "Goodbye!")
