const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const lwip = idf.lwip;
const sys = idf.sys;
const log = std.log;

// Import modular components
const config = @import("config.zig");
const DashboardHtml = @import("dashboardHtml.zig").DashboardHtml;
const TerminalService = @import("terminalService.zig").TerminalService;
const FsService = @import("fsService.zig").FsService;

/// ESP32 HTTP Service - serves dashboard and handles API requests
pub const HttpService = struct {
    // LwIP constants
    const AF_INET = 2;
    const SOCK_STREAM = 1;
    const SOL_SOCKET = 0xfff;
    const SO_REUSEADDR = 0x0004;
    const IPPROTO_TCP = 6;

    var server_socket: c_int = -1;
    var led_state: bool = false;
    var current_ip: [16]u8 = undefined;

    /// Initialize LED GPIO
    fn initLed() void {
        _ = sys.gpio_reset_pin(config.Config.LED_GPIO);
        _ = sys.gpio_set_direction(config.Config.LED_GPIO, sys.GPIO_MODE_OUTPUT);
        _ = sys.gpio_set_level(config.Config.LED_GPIO, 0);
    }

    /// Toggle LED and return new state
    fn toggleLed() bool {
        led_state = !led_state;
        _ = sys.gpio_set_level(config.Config.LED_GPIO, if (led_state) 1 else 0);
        return led_state;
    }

    /// Get current IP address as string
    pub fn getIpAddress() []const u8 {
        var ip_info: sys.esp_netif_ip_info_t = undefined;
        const netif = sys.esp_netif_get_handle_from_ifkey("WIFI_STA_DEF");
        if (netif != null) {
            if (sys.esp_netif_get_ip_info(netif, &ip_info) == sys.ESP_OK) {
                // Format IP - simplified, return placeholder for now
                return "192.168.x.x";
            }
        }
        return "0.0.0.0";
    }

    /// Start the HTTP server
    pub fn start_webserver() !void {
        initLed();

        // Create socket
        server_socket = lwip.lwip_socket(AF_INET, SOCK_STREAM, 0);
        if (server_socket < 0) {
            log.err("Failed to create socket", .{});
            return error.SocketCreationFailed;
        }
        log.info("Socket created", .{});

        // Set socket options
        var opt: c_int = 1;
        _ = lwip.lwip_setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, @sizeOf(c_int));

        // Bind to port
        var server_addr = lwip.sockaddr_in{
            .sin_len = @sizeOf(lwip.sockaddr_in),
            .sin_family = AF_INET,
            .sin_port = lwip.lwip_htons(config.Config.PORT),
            .sin_addr = .{ .s_addr = 0 }, // INADDR_ANY
            .sin_zero = [_]u8{0} ** 8,
        };

        if (lwip.lwip_bind(server_socket, @ptrCast(&server_addr), @sizeOf(lwip.sockaddr_in)) < 0) {
            log.err("Failed to bind socket", .{});
            _ = lwip.lwip_close(server_socket);
            return error.BindFailed;
        }
        log.info("Socket bound to port {}", .{config.Config.PORT});

        // Listen
        if (lwip.lwip_listen(server_socket, config.Config.MAX_CONNECTIONS) < 0) {
            log.err("Failed to listen", .{});
            _ = lwip.lwip_close(server_socket);
            return error.ListenFailed;
        }

        log.info("HTTP server started on port {}", .{config.Config.PORT});
        log.info("Access dashboard at http://<IP>:{}", .{config.Config.PORT});

        // Accept loop
        var client_addr: lwip.sockaddr_in = undefined;
        var addr_len: u32 = @sizeOf(lwip.sockaddr_in);

        while (true) {
            const client_socket = lwip.lwip_accept(server_socket, @ptrCast(&client_addr), &addr_len);
            if (client_socket >= 0) {
                handleClient(client_socket);
            }
        }
    }

    /// Handle incoming client request
    fn handleClient(client_socket: c_int) void {
        var buffer: [config.Config.BUFFER_SIZE]u8 = undefined;
        const bytes_read = lwip.lwip_recv(client_socket, &buffer, config.Config.BUFFER_SIZE - 1, 0);

        if (bytes_read > 0) {
            buffer[@intCast(bytes_read)] = 0;
            const request = buffer[0..@intCast(bytes_read)];

            // Route request
            if (std.mem.startsWith(u8, request, "GET / ") or std.mem.startsWith(u8, request, "GET /index")) {
                sendDashboard(client_socket);
            } else if (std.mem.startsWith(u8, request, "GET /api/status")) {
                sendStatus(client_socket);
            } else if (std.mem.startsWith(u8, request, "POST /api/led")) {
                sendLedToggle(client_socket);
            } else if (std.mem.startsWith(u8, request, "POST /api/terminal/exec")) {
                handleTerminal(client_socket, request);
            } else if (std.mem.startsWith(u8, request, "GET /api/fs/list")) {
                sendFileList(client_socket);
            } else if (std.mem.startsWith(u8, request, "OPTIONS")) {
                sendCorsOptions(client_socket);
            } else {
                send404(client_socket);
            }
        }

        _ = lwip.lwip_close(client_socket);
    }

    /// Send dashboard HTML
    fn sendDashboard(client: c_int) void {
        _ = lwip.lwip_send(client, DashboardHtml.html_headers.ptr, DashboardHtml.html_headers.len, 0);
        _ = lwip.lwip_send(client, DashboardHtml.index_html.ptr, DashboardHtml.index_html.len, 0);
    }

    /// Send status JSON
    fn sendStatus(client: c_int) void {
        const heap = sys.esp_get_free_heap_size();
        const heap_kb = heap / 1024;

        // Build JSON response - simplified without uptime
        var response_buf: [256]u8 = undefined;
        const json = std.fmt.bufPrint(&response_buf,
            \\{{"status":"ok","heap":{},"led":{}}}
        , .{ heap_kb, led_state }) catch "{\"error\":\"format\"}";

        _ = lwip.lwip_send(client, DashboardHtml.json_headers.ptr, DashboardHtml.json_headers.len, 0);
        _ = lwip.lwip_send(client, json.ptr, json.len, 0);
    }

    /// Toggle LED and send response
    fn sendLedToggle(client: c_int) void {
        const state = toggleLed();
        const json = if (state)
            \\{"led_on":true}
        else
            \\{"led_on":false}
        ;
        _ = lwip.lwip_send(client, DashboardHtml.json_headers.ptr, DashboardHtml.json_headers.len, 0);
        _ = lwip.lwip_send(client, json.ptr, json.len, 0);
    }

    /// Handle terminal command execution
    fn handleTerminal(client: c_int, request: []const u8) void {
        // Parse JSON body to get command
        // Simple parsing: find "cmd":"<value>"
        var cmd: []const u8 = "";

        if (std.mem.indexOf(u8, request, "\"cmd\":\"")) |start| {
            const cmd_start = start + 7;
            if (std.mem.indexOfPos(u8, request, cmd_start, "\"")) |end| {
                cmd = request[cmd_start..end];
            }
        }

        const result = TerminalService.execute(cmd);

        // Build response
        var response_buf: [512]u8 = undefined;
        const json = std.fmt.bufPrint(&response_buf,
            \\{{"output":"{s}","success":{}}}
        , .{ result.output, result.success }) catch
            \\{"output":"Error","success":false}
        ;

        _ = lwip.lwip_send(client, DashboardHtml.json_headers.ptr, DashboardHtml.json_headers.len, 0);
        _ = lwip.lwip_send(client, json.ptr, json.len, 0);
    }

    /// Send file list
    fn sendFileList(client: c_int) void {
        const files = FsService.listFiles("/spiffs") catch
            \\{"files":[],"error":"Not mounted"}
        ;
        _ = lwip.lwip_send(client, DashboardHtml.json_headers.ptr, DashboardHtml.json_headers.len, 0);
        _ = lwip.lwip_send(client, files.ptr, files.len, 0);
    }

    /// Send CORS preflight response
    fn sendCorsOptions(client: c_int) void {
        const response =
            \\HTTP/1.1 204 No Content
            \\Access-Control-Allow-Origin: *
            \\Access-Control-Allow-Methods: GET, POST, OPTIONS
            \\Access-Control-Allow-Headers: Content-Type
            \\Connection: close
            \\
            \\
        ;
        _ = lwip.lwip_send(client, response.ptr, response.len, 0);
    }

    /// Send 404 response
    fn send404(client: c_int) void {
        _ = lwip.lwip_send(client, DashboardHtml.not_found.ptr, DashboardHtml.not_found.len, 0);
    }
};
