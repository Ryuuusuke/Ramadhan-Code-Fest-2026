const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const sys = idf.sys;
const log = std.log;
const config = @import("config.zig");
const FsService = @import("fsService.zig").FsService;

/// Terminal Service - handles shell-like commands
pub const TerminalService = struct {
    /// Command result
    pub const CommandResult = struct {
        output: []const u8,
        success: bool,
    };

    /// Execute a command and return result
    pub fn execute(cmd_line: []const u8) CommandResult {
        // Parse command
        var cmd = cmd_line;

        // Trim whitespace
        while (cmd.len > 0 and (cmd[0] == ' ' or cmd[0] == '\t' or cmd[0] == '\n' or cmd[0] == '\r')) {
            cmd = cmd[1..];
        }
        while (cmd.len > 0 and (cmd[cmd.len - 1] == ' ' or cmd[cmd.len - 1] == '\t' or cmd[cmd.len - 1] == '\n' or cmd[cmd.len - 1] == '\r')) {
            cmd = cmd[0 .. cmd.len - 1];
        }

        if (cmd.len == 0) {
            return .{ .output = "", .success = true };
        }

        // Match commands
        if (std.mem.eql(u8, cmd, "help")) {
            return cmdHelp();
        } else if (std.mem.eql(u8, cmd, "status")) {
            return cmdStatus();
        } else if (std.mem.eql(u8, cmd, "heap")) {
            return cmdHeap();
        } else if (std.mem.eql(u8, cmd, "uptime")) {
            return cmdUptime();
        } else if (std.mem.eql(u8, cmd, "wifi")) {
            return cmdWifi();
        } else if (std.mem.eql(u8, cmd, "reboot")) {
            return cmdReboot();
        } else if (std.mem.startsWith(u8, cmd, "ls")) {
            return cmdLs(cmd);
        } else if (std.mem.startsWith(u8, cmd, "cat ")) {
            return cmdCat(cmd[4..]);
        } else if (std.mem.startsWith(u8, cmd, "rm ")) {
            return cmdRm(cmd[3..]);
        } else {
            return .{ .output = "Unknown command. Type 'help' for available commands.", .success = false };
        }
    }

    fn cmdHelp() CommandResult {
        return .{
            .output =
            \\Available commands:
            \\  help     - Show this help
            \\  status   - Show ESP32 status
            \\  heap     - Show heap info
            \\  uptime   - Show uptime
            \\  wifi     - Show WiFi info
            \\  ls [dir] - List files
            \\  cat file - Read file
            \\  rm file  - Delete file
            \\  reboot   - Restart ESP32
            ,
            .success = true,
        };
    }

    fn cmdStatus() CommandResult {
        return .{
            .output = "ESP32 Status: Running\nFree heap: " ++ "checking..." ++ "\nCPU: Xtensa LX6 @ 160MHz",
            .success = true,
        };
    }

    fn cmdHeap() CommandResult {
        // Note: Would need runtime formatting for actual values
        return .{
            .output = "Free heap: checking...\nMin free: checking...",
            .success = true,
        };
    }

    fn cmdUptime() CommandResult {
        return .{
            .output = "Uptime: checking...",
            .success = true,
        };
    }

    fn cmdWifi() CommandResult {
        return .{
            .output = "WiFi Status: Connected\nSSID: checking...\nIP: checking...",
            .success = true,
        };
    }

    fn cmdReboot() CommandResult {
        // Schedule reboot
        log.info("Reboot requested via terminal", .{});
        // sys.esp_restart(); // Would be called after response
        return .{
            .output = "Rebooting...",
            .success = true,
        };
    }

    fn cmdLs(cmd: []const u8) CommandResult {
        _ = cmd;
        if (!FsService.isMounted()) {
            return .{ .output = "Error: Filesystem not mounted", .success = false };
        }
        return .{ .output = "Listing files...", .success = true };
    }

    fn cmdCat(path: []const u8) CommandResult {
        _ = path;
        if (!FsService.isMounted()) {
            return .{ .output = "Error: Filesystem not mounted", .success = false };
        }
        return .{ .output = "Reading file...", .success = true };
    }

    fn cmdRm(path: []const u8) CommandResult {
        _ = path;
        if (!FsService.isMounted()) {
            return .{ .output = "Error: Filesystem not mounted", .success = false };
        }
        return .{ .output = "Deleting file...", .success = true };
    }
};
