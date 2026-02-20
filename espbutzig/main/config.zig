const std = @import("std");
const builtin = @import("builtin");
const idf = @import("esp_idf");
const sys = idf.sys;
const log = std.log;

/// Configuration for the ESP32 HTTP Dashboard
pub const Config = struct {
    /// HTTP server port
    pub const PORT: u16 = 5000;

    /// Maximum connections
    pub const MAX_CONNECTIONS: c_int = 5;

    /// Buffer size for requests
    pub const BUFFER_SIZE: usize = 2048;

    /// SPIFFS mount point
    pub const SPIFFS_MOUNT: [:0]const u8 = "/spiffs";

    /// LED GPIO for status
    pub const LED_GPIO = sys.GPIO_NUM_18;
};
