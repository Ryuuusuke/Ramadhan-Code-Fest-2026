const std = @import("std");
const builtin = @import("builtin");

/// Dashboard HTML module - contains embedded HTML/CSS/JS for the web dashboard
pub const DashboardHtml = struct {
    /// Main dashboard page HTML with Tailwind CSS (via CDN)
    pub const index_html =
        \\<!DOCTYPE html>
        \\<html lang="en" class="dark">
        \\<head>
        \\  <meta charset="UTF-8">
        \\  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        \\  <title>ESP32 Dashboard</title>
        \\  <script src="https://cdn.tailwindcss.com"></script>
        \\  <script>
        \\    tailwind.config = {
        \\      darkMode: 'class',
        \\      theme: {
        \\        extend: {
        \\          colors: {
        \\            esp: { 500: '#10B981', 600: '#059669' }
        \\          }
        \\        }
        \\      }
        \\    }
        \\  </script>
        \\  <style>
        \\    .terminal { font-family: 'Courier New', monospace; }
        \\    .terminal-output { max-height: 300px; overflow-y: auto; }
        \\    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        \\    .pulse { animation: pulse 2s infinite; }
        \\  </style>
        \\</head>
        \\<body class="bg-gray-900 text-gray-100 min-h-screen">
        \\  <!-- Header -->
        \\  <header class="bg-gray-800 border-b border-gray-700 px-6 py-4">
        \\    <div class="flex items-center justify-between">
        \\      <div class="flex items-center gap-3">
        \\        <div class="w-3 h-3 rounded-full bg-green-500 pulse"></div>
        \\        <h1 class="text-xl font-bold text-esp-500">ESP32 Dashboard</h1>
        \\      </div>
        \\      <div class="flex items-center gap-4 text-sm text-gray-400">
        \\        <span id="ip-display">IP: Loading...</span>
        \\        <span id="uptime-display">Uptime: 0s</span>
        \\        <span id="heap-display">Heap: --</span>
        \\      </div>
        \\    </div>
        \\  </header>
        \\
        \\  <main class="container mx-auto p-6 grid gap-6 lg:grid-cols-2">
        \\    <!-- Terminal Panel -->
        \\    <div class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
        \\      <div class="bg-gray-750 px-4 py-2 border-b border-gray-700 flex items-center gap-2">
        \\        <div class="flex gap-1.5">
        \\          <div class="w-3 h-3 rounded-full bg-red-500"></div>
        \\          <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
        \\          <div class="w-3 h-3 rounded-full bg-green-500"></div>
        \\        </div>
        \\        <span class="text-sm text-gray-400 ml-2">Terminal</span>
        \\      </div>
        \\      <div id="terminal-output" class="terminal terminal-output p-4 bg-gray-900 text-green-400 text-sm">
        \\        <div>ESP32 Terminal v1.0</div>
        \\        <div>Type 'help' for available commands</div>
        \\        <div>&nbsp;</div>
        \\      </div>
        \\      <div class="flex border-t border-gray-700">
        \\        <span class="px-3 py-2 text-green-500 terminal">$</span>
        \\        <input type="text" id="terminal-input" 
        \\          class="flex-1 bg-gray-900 text-green-400 terminal px-2 py-2 outline-none"
        \\          placeholder="Enter command..." autofocus>
        \\      </div>
        \\    </div>
        \\
        \\    <!-- Status Panel -->
        \\    <div class="bg-gray-800 rounded-lg border border-gray-700 p-4">
        \\      <h2 class="text-lg font-semibold mb-4 text-esp-500">System Status</h2>
        \\      <div class="grid gap-4">
        \\        <div class="bg-gray-900 rounded p-3">
        \\          <div class="text-sm text-gray-400">WiFi Status</div>
        \\          <div id="wifi-status" class="text-lg font-medium text-green-400">Connected</div>
        \\        </div>
        \\        <div class="bg-gray-900 rounded p-3">
        \\          <div class="text-sm text-gray-400">Free Heap</div>
        \\          <div id="free-heap" class="text-lg font-medium">-- KB</div>
        \\        </div>
        \\        <div class="bg-gray-900 rounded p-3">
        \\          <div class="text-sm text-gray-400">CPU Frequency</div>
        \\          <div class="text-lg font-medium">160 MHz</div>
        \\        </div>
        \\        <div class="bg-gray-900 rounded p-3">
        \\          <div class="text-sm text-gray-400">LED Status</div>
        \\          <button id="led-toggle" onclick="toggleLed()"
        \\            class="mt-1 px-4 py-1 bg-esp-600 hover:bg-esp-500 rounded text-sm transition">
        \\            Toggle LED
        \\          </button>
        \\        </div>
        \\      </div>
        \\    </div>
        \\
        \\    <!-- Files Panel -->
        \\    <div class="bg-gray-800 rounded-lg border border-gray-700 p-4 lg:col-span-2">
        \\      <h2 class="text-lg font-semibold mb-4 text-esp-500">File System (SPIFFS)</h2>
        \\      <div id="file-list" class="grid gap-2">
        \\        <div class="text-gray-400 text-sm">Loading files...</div>
        \\      </div>
        \\    </div>
        \\  </main>
        \\
        \\  <script>
        \\    const terminalOutput = document.getElementById('terminal-output');
        \\    const terminalInput = document.getElementById('terminal-input');
        \\    
        \\    // Terminal input handler
        \\    terminalInput.addEventListener('keypress', async (e) => {
        \\      if (e.key === 'Enter') {
        \\        const cmd = terminalInput.value.trim();
        \\        if (!cmd) return;
        \\        
        \\        appendOutput('$ ' + cmd);
        \\        terminalInput.value = '';
        \\        
        \\        try {
        \\          const res = await fetch('/api/terminal/exec', {
        \\            method: 'POST',
        \\            headers: { 'Content-Type': 'application/json' },
        \\            body: JSON.stringify({ cmd })
        \\          });
        \\          const data = await res.json();
        \\          appendOutput(data.output || 'No output');
        \\        } catch (err) {
        \\          appendOutput('Error: ' + err.message);
        \\        }
        \\      }
        \\    });
        \\    
        \\    function appendOutput(text) {
        \\      const div = document.createElement('div');
        \\      div.textContent = text;
        \\      terminalOutput.appendChild(div);
        \\      terminalOutput.scrollTop = terminalOutput.scrollHeight;
        \\    }
        \\    
        \\    async function toggleLed() {
        \\      try {
        \\        const res = await fetch('/api/led', { method: 'POST' });
        \\        const data = await res.json();
        \\        appendOutput('LED: ' + (data.led_on ? 'ON' : 'OFF'));
        \\      } catch (err) {
        \\        appendOutput('LED Error: ' + err.message);
        \\      }
        \\    }
        \\    
        \\    async function updateStatus() {
        \\      try {
        \\        const res = await fetch('/api/status');
        \\        const data = await res.json();
        \\        document.getElementById('ip-display').textContent = 'IP: ' + (data.ip || 'Unknown');
        \\        document.getElementById('heap-display').textContent = 'Heap: ' + (data.heap || '--') + ' KB';
        \\        document.getElementById('free-heap').textContent = (data.heap || '--') + ' KB';
        \\      } catch (err) {}
        \\    }
        \\    
        \\    // Update status every 5 seconds
        \\    updateStatus();
        \\    setInterval(updateStatus, 5000);
        \\  </script>
        \\</body>
        \\</html>
    ;

    /// HTTP headers for HTML response
    pub const html_headers = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n";

    /// HTTP headers for JSON response
    pub const json_headers = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n";

    /// 404 response
    pub const not_found = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n404 Not Found";
};
