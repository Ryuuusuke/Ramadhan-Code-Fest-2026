const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const wifi = idf.wifi;
const ConnectWifi = @import("connectWifi.zig").ConnectWifi;
const HttpService = @import("httpService.zig").HttpService;
const ver = idf.ver.Version;

export fn app_main() callconv(.c) void {
    // Wait for FreeRTOS to fully initialize
    idf.rtos.vTaskDelay(100 / idf.rtos.portTICK_PERIOD_MS);

    log.info("Hello, ESP32 HTTP Server from Zig!", .{});

    log.info(
        \\[Zig Info]
        \\* Version: {s}
        \\* Compiler Backend: {s}
        \\
    , .{
        @as([]const u8, builtin.zig_version_string),
        @tagName(builtin.zig_backend),
    });

    var heap = idf.heap.HeapCapsAllocator.init(.MALLOC_CAP_8BIT);
    var arena = std.heap.ArenaAllocator.init(heap.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    idf.log.ESP_LOG(allocator, tag,
        \\[ESP-IDF Info]
        \\* Version: {s}
        \\
    , .{ver.get().toString(allocator)});

    // Initialize WiFi first
    ConnectWifi.wifi_init() catch |err| {
        log.err("WiFi init failed: {s}", .{@errorName(err)});
        return;
    };

    // Wait for WiFi connection
    idf.rtos.vTaskDelay(5000 / idf.rtos.portTICK_PERIOD_MS);

    // Start HTTP server
    HttpService.start_webserver() catch |err| {
        log.err("HTTP server start failed: {s}", .{@errorName(err)});
        return;
    };
    // Note: start_webserver() contains a blocking accept loop,
    // so this code is only reached if the server stops
}

// Override std panic with idf panic
pub const panic = idf.esp_panic.panic;
const log = std.log.scoped(.@"esp-http");
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = idf.log.espLogFn,
};

const tag = "esp-http";
