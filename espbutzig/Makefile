PROJECT_NAME := trainEsp

# Default paths and settings
# Adjust this if your esp-idf is elsewhere
IDF_PATH ?= $(HOME)/esp/esp-idf
# Try to match the user's relative path if possible, or fallback
REAL_IDF_PATH := $(shell if [ -d "../../C++/esp-idf" ]; then echo "../../C++/esp-idf"; else echo $(IDF_PATH); fi)
IDF_EXPORT_SCRIPT ?= $(REAL_IDF_PATH)/export.sh

PORT ?= /dev/ttyUSB0
BAUD ?= 115200

# Command wrapper
# If idf.py is not in PATH, try to source the export script
IDF_CHECK := $(shell which idf.py 2> /dev/null)
ifeq ($(IDF_CHECK),)
    IDF_CMD = . $(IDF_EXPORT_SCRIPT) > /dev/null && idf.py
else
    IDF_CMD = idf.py
endif

.PHONY: all build clean flash monitor menuconfig help run

all: build

build:
	@echo "Building project..."
	@bash -c '$(IDF_CMD) build'

clean:
	@echo "Cleaning project..."
	@bash -c '$(IDF_CMD) fullclean'

flash:
	@echo "Flashing firmware to $(PORT)..."
	@bash -c 'sudo chmod 666 ${PORT}'
	@bash -c '$(IDF_CMD) -p $(PORT) -b $(BAUD) flash'

monitor:
	@echo "Starting monitor on $(PORT)..."
	@bash -c 'sudo chmod 666 ${PORT}'
	@bash -c '$(IDF_CMD) -p $(PORT) -b $(BAUD) monitor'

menuconfig:
	@bash -c '$(IDF_CMD) menuconfig'

run: flash monitor

help:
	@echo "Makefile for $(PROJECT_NAME)"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all         Build the project (default)"
	@echo "  build       Compile the project"
	@echo "  clean       Full clean of the build directory"
	@echo "  flash       Flash the firmware"
	@echo "  monitor     Open the serial monitor"
	@echo "  run         Flash and then monitor"
	@echo "  menuconfig  Open the configuration menu"
	@echo ""
	@echo "Configuration:"
	@echo "  PORT        $(PORT) (Override with PORT=/dev/ttyUSBx)"
	@echo "  BAUD        $(BAUD)"