const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const wifi = idf.wifi;
const sys = idf.sys;
const log = std.log;

pub const ConnectWifi = struct {
    // WiFi credentials structure
    const WifiCredentials = struct {
        ssid: [:0]const u8,
        password: [:0]const u8,
    };

    // List of WiFi networks to try (in order of priority)
    const wifi_list = [_]WifiCredentials{
        .{ .ssid = "Galaxy A031717", .password = "bundaa79" },
        .{ .ssid = "SamsungA12", .password = "ndaktautanyasaya" },
    };

    fn stringToArray(comptime size: usize, str: [:0]const u8) [size]u8 {
        var arr: [size]u8 = undefined;
        @memset(&arr, 0);
        const len = @min(str.len, size);
        @memcpy(arr[0..len], str[0..len]);
        return arr;
    }

    fn tryConnect(creds: WifiCredentials) bool {
        log.info("Trying to connect to: {s}", .{creds.ssid});

        var conf: wifi.wifiConfig = .{
            .sta = .{
                .ssid = stringToArray(32, creds.ssid),
                .password = stringToArray(64, creds.password),
            },
        };

        wifi.setConfig(.WIFI_IF_STA, &conf) catch |err| {
            log.warn("Failed to set config for {s}: {s}", .{ creds.ssid, @errorName(err) });
            return false;
        };

        wifi.connect() catch |err| {
            log.warn("Failed to connect to {s}: {s}", .{ creds.ssid, @errorName(err) });
            return false;
        };

        // Wait for connection to establish (5 seconds)
        log.info("Waiting for WiFi connection...", .{});
        idf.rtos.vTaskDelay(5000 / idf.rtos.portTICK_PERIOD_MS);

        // Assume connected if no error was thrown
        // In real implementation, you would use event handlers
        log.info("Connected to {s}! (assumed)", .{creds.ssid});
        return true;
    }

    pub fn wifi_init() !void {
        // Initialize NVS (Non-Volatile Storage) - required for WiFi
        const nvs_ret = sys.nvs_flash_init();
        if (nvs_ret == sys.ESP_ERR_NVS_NO_FREE_PAGES or nvs_ret == sys.ESP_ERR_NVS_NEW_VERSION_FOUND) {
            // NVS partition was truncated, need to erase
            _ = sys.nvs_flash_erase();
            _ = sys.nvs_flash_init();
        }
        log.info("NVS initialized", .{});

        // Initialize TCP/IP adapter
        _ = sys.esp_netif_init();
        _ = sys.esp_event_loop_create_default();
        _ = sys.esp_netif_create_default_wifi_sta();
        log.info("Network interface initialized", .{});

        // Use default config (WIFI_INIT_CONFIG_DEFAULT equivalent)
        var wifi_config = wifi.init_config_default();
        try wifi.init(&wifi_config);
        try wifi.setMode(.WIFI_MODE_STA);
        try wifi.start();

        log.info("WiFi initialized, trying {} networks...", .{wifi_list.len});

        // Try each WiFi network in the list
        for (wifi_list) |creds| {
            if (tryConnect(creds)) {
                log.info("WiFi connection successful!", .{});

                // Get and log IP address
                var ip_info: sys.esp_netif_ip_info_t = undefined;
                const netif = sys.esp_netif_get_handle_from_ifkey("WIFI_STA_DEF");
                if (netif != null) {
                    if (sys.esp_netif_get_ip_info(netif, &ip_info) == sys.ESP_OK) {
                        const ip = ip_info.ip.addr;
                        log.info("=================================", .{});
                        log.info("IP Address: {}.{}.{}.{}", .{ ip & 0xFF, (ip >> 8) & 0xFF, (ip >> 16) & 0xFF, (ip >> 24) & 0xFF });
                        log.info("Dashboard: http://{}.{}.{}.{}:5000", .{ ip & 0xFF, (ip >> 8) & 0xFF, (ip >> 16) & 0xFF, (ip >> 24) & 0xFF });
                        log.info("=================================", .{});
                    }
                }
                return;
            }
            // Wait a bit before trying next network
            idf.rtos.vTaskDelay(1000 / idf.rtos.portTICK_PERIOD_MS);
        }

        // All networks failed
        log.err("Failed to connect to any WiFi network!", .{});
        return error.NoWifiConnection;
    }
};
