# USB Audio Mapper

A robust Linux utility for creating persistent naming rules for USB audio capture devices (microphones), ensuring they maintain consistent names across reboots.

## Overview

USB Audio Mapper creates udev rules to persistently name your USB audio devices in Linux. This solves the common issue where USB audio devices may change names (card0, card1, etc.) when other devices are connected or after reboots, causing configuration and application problems.

**Version**: 2.0 (Enhanced robustness and reliability)

## Features

- Creates comprehensive udev rules for reliable device identification
- Provides persistent device names and symlinks for easy access
- Handles multiple identical devices correctly by detecting physical USB ports
- Supports both interactive and non-interactive operation
- Detects device vendor/product IDs, USB paths, and platform-specific paths
- Works across different Linux distributions with varying device path formats
- Atomic file operations prevent corruption during rule updates
- Comprehensive error handling and validation
- Signal handling for safe interruption

## Common Problems Solved

The USB Audio Mapper addresses several common issues that Linux users face with USB audio devices:

1. **Inconsistent Device Ordering**: 
   - **Problem**: USB audio devices are assigned card numbers (card0, card1) based on detection order
   - **Impact**: After a reboot, your USB microphone that was previously card1 might become card2
   - **Consequence**: Applications configured to use a specific card number stop working

2. **Configuration Persistence**:
   - **Problem**: Audio settings and configurations often reference specific card names/numbers
   - **Impact**: When card numbers change, your carefully configured ALSA or PulseAudio settings break
   - **Consequence**: Requires manual reconfiguration after each device change or reboot

3. **Multiple Identical Devices**:
   - **Problem**: Two identical USB microphones appear the same to the system
   - **Impact**: No reliable way to distinguish between them in applications
   - **Consequence**: Unable to create reliable multi-microphone setups

4. **Application Startup Dependencies**:
   - **Problem**: Applications that auto-start may initialize before all USB devices are detected
   - **Impact**: Applications might use the wrong audio device or fail to find expected devices
   - **Consequence**: Requires manual intervention or complex startup scripts

5. **Hardware Swapping**:
   - **Problem**: Temporarily disconnecting a device can change the ordering of all other devices
   - **Impact**: Disconnecting one device can break configurations for all other audio devices
   - **Consequence**: Makes working with multiple USB audio devices frustrating

USB Audio Mapper solves these issues by creating persistent, reliable device names and paths that remain consistent regardless of connection order or system changes. For best results, keep devices plugged into the same USB port once configured.

## Requirements

**Required commands**:
- `lsusb` - For listing USB devices
- `udevadm` - For udev rule management
- `grep`, `sed`, `cat` - Standard text processing utilities

**Optional commands**:
- `aplay` - For listing ALSA devices (enhanced functionality)

The script will check for these dependencies at startup and report any missing commands.

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/tomtom215/usb-audio-mapper/main/usb-soundcard-mapper.sh
   # or
   wget https://raw.githubusercontent.com/tomtom215/usb-audio-mapper/main/usb-soundcard-mapper.sh
   ```

2. Make it executable:
   ```bash
   chmod +x usb-soundcard-mapper.sh
   ```

3. (Optional) Move to system path:
   ```bash
   sudo mv usb-soundcard-mapper.sh /usr/local/bin/
   ```

## Usage

### Interactive Mode

Run the script with no arguments to enter interactive mode:

```bash
sudo ./usb-soundcard-mapper.sh
```

Follow the prompts to:
1. Select a sound card from the detected USB audio devices
2. Confirm the corresponding USB device
3. Enter a friendly name for the device (lowercase letters, numbers, and hyphens only, max 32 characters)
4. Optionally reboot to apply the changes

### Non-Interactive Mode

For scripting or automating device naming:

```bash
sudo ./usb-soundcard-mapper.sh -n -d "DEVICE_NAME" -v VENDOR_ID -p PRODUCT_ID -f FRIENDLY_NAME
```

Required parameters:
- `-d` : Device name (descriptive, for logging only)
- `-v` : Vendor ID (4-digit hex, case insensitive)
- `-p` : Product ID (4-digit hex, case insensitive)
- `-f` : Friendly name (will be used in device paths, must start with letter)

Optional parameters:
- `-u` : USB port path (helps with multiple identical devices)

Example:
```bash
sudo ./usb-soundcard-mapper.sh -n -d "MOVO X1 MINI" -v 2e88 -p 4610 -f movo-mic
```

### Additional Options

- `-t, --test` : Test USB port detection capabilities
- `-D, --debug` : Enable debug output for troubleshooting
- `-h, --help` : Display help information

## Validation

After running the script and rebooting, verify the mapping worked:

1. **Check the sound card list**:
   ```bash
   cat /proc/asound/cards
   ```
   Your device should appear with the friendly name you chose.

2. **List ALSA devices**:
   ```bash
   arecord -l  # For input devices (microphones)
   aplay -l    # For output devices (speakers)
   ```

3. **Verify the udev rules**:
   ```bash
   sudo cat /etc/udev/rules.d/99-usb-soundcards.rules
   ```
   Should show three rule types for your device (basic, USB path, platform ID).

4. **Check the symlink was created**:
   ```bash
   ls -la /dev/sound/by-id/
   ```
   Should show a symlink with your friendly name.

## Troubleshooting

### Device Not Being Renamed

1. **Check the udev rules were created**:
   ```bash
   sudo cat /etc/udev/rules.d/99-usb-soundcards.rules
   ```

2. **Reload the udev rules manually**:
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. **Verify device information matches**:
   ```bash
   lsusb | grep -i audio
   ```
   Check that the vendor and product IDs in the rule match the actual device.

4. **Run with debug logging**:
   ```bash
   sudo ./usb-soundcard-mapper.sh -D
   ```

5. **Check system logs**:
   ```bash
   sudo journalctl -f
   # In another terminal, unplug and replug the USB device
   ```

### Multiple Identical Devices

If you have multiple identical USB audio devices:

1. **Connect one device at a time** and run the script for each
2. Use different USB ports for each device
3. Ensure each device gets a unique friendly name
4. The script will attempt to detect physical USB ports to differentiate devices

### Path Identification Issues

For devices with detection problems:

1. **Test port detection capability**:
   ```bash
   sudo ./usb-soundcard-mapper.sh -t
   ```

2. **Get detailed device information**:
   ```bash
   # Replace X with your card number
   sudo udevadm info -a -n /dev/snd/controlCX
   ```

3. **Monitor udev events**:
   ```bash
   sudo udevadm monitor --environment --udev
   # Then plug in the device
   ```

### Warning Messages

**"Could not get complete USB information"**: This warning is informational and doesn't prevent the script from working. It means some detection methods couldn't parse the device information, but the fallback methods will handle it correctly.

## Uninstallation

To remove all persistent naming rules:

1. **Delete the udev rules file**:
   ```bash
   sudo rm /etc/udev/rules.d/99-usb-soundcards.rules
   ```

2. **Reload udev rules**:
   ```bash
   sudo udevadm control --reload-rules
   ```

3. **Reboot to restore default naming**:
   ```bash
   sudo reboot
   ```

To remove rules for a specific device only, edit the rules file and delete the relevant lines:
```bash
sudo nano /etc/udev/rules.d/99-usb-soundcards.rules
# Delete the lines for your specific device
sudo udevadm control --reload-rules
```

## How It Works

### Linux Device Management and udev

In Linux, when devices are connected, the kernel detects them and creates device nodes in the `/dev` directory. The udev system (part of systemd in modern distributions) manages these device nodes dynamically.

Without persistence rules, ALSA (Advanced Linux Sound Architecture) assigns sound card indices (0, 1, 2...) based on the order of detection, which can change between reboots or when devices are added/removed.

### udev Rules Mechanism

The udev system uses rules files (stored in `/etc/udev/rules.d/` and `/usr/lib/udev/rules.d/`) to determine how to name and configure devices. Rules are processed in lexicographical order by filename, which is why this script creates a file named `99-usb-soundcards.rules` to ensure it runs after standard rules.

When a device event occurs (like plugging in a USB sound card), udev:
1. Gathers all attributes of the device
2. Processes all rules in order
3. Applies matching rules to configure the device

### Rule Types and Matching

The script creates three types of udev rules for maximum compatibility:

1. **Vendor/Product ID rule**:
   ```
   SUBSYSTEM=="sound", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="sound/by-id/friendly-name", ATTR{id}="friendly-name"
   ```
   - Matches any sound device with specific vendor and product IDs
   - Uses the ATTRS{} operator which searches up the device chain
   - Provides a baseline match for the device type

2. **USB Path rule**:
   ```
   SUBSYSTEM=="sound", KERNELS=="usb-X.Y", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="sound/by-id/friendly-name", ATTR{id}="friendly-name"
   ```
   - KERNELS matches against the device path in the kernel
   - Includes physical USB port information (X.Y represents port numbers)
   - Can distinguish between identical devices on different USB ports

3. **Platform Path rule**:
   ```
   SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-controller-usb-0:X.Y:1.0", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="sound/by-id/friendly-name", ATTR{id}="friendly-name"
   ```
   - Uses ENV{ID_PATH} which contains a complete platform-specific path
   - Provides the most specific matching for the exact hardware path
   - Works reliably even with complex USB topologies (hubs, etc.)

### Actions and Persistence

When a rule matches, it performs two key actions:

1. **ATTR{id}="friendly-name"** - Sets the ALSA card ID (appears in `/proc/asound/cards`)
2. **SYMLINK+="sound/by-id/friendly-name"** - Creates a persistent symlink in `/dev/sound/by-id/`

These settings persist across reboots because:
- Rules are stored in `/etc/udev/rules.d/` which survives reboots
- udev processes these rules every time the device is connected
- The same friendly name is always assigned regardless of detection order

## Use Cases

### Professional Audio Production

- **Recording Studios**: Multiple audio interfaces with consistent routing
- **Live Performance**: Reliable device naming between shows
- **Podcasting/Streaming**: Consistent microphone identification

### Multi-Device Setups

- **Multiple Identical Devices**: Distinguish between identical USB microphones
- **Complex Audio Routing**: Stable device paths for multi-channel setups
- **Video Conferencing**: Ensure correct microphone selection

### Automated Systems

- **Kiosks & Digital Signage**: Reliable audio after unattended reboots
- **Embedded Applications**: Industrial systems with specific audio requirements
- **CI/CD Testing**: Automated testing of audio equipment

### Educational and Home Use

- **Computer Labs**: Consistent configuration across workstations
- **HTPC/Media Centers**: Reliable audio device mapping
- **Raspberry Pi Projects**: Essential for headless audio projects

## Changelog

### Version 2.0 (Current)
- Added comprehensive error checking for all operations
- Implemented atomic file operations for rule updates
- Added dependency checking at startup
- Enhanced input validation and bounds checking
- Added signal handling for safe interruption
- Fixed variable quoting throughout
- Improved shellcheck compliance
- Better error messages with actionable guidance

### Version 1.0
- Initial release with core functionality
- Multi-method USB device detection
- Interactive and non-interactive modes
- Three-rule approach for maximum compatibility

## License

USB Audio Mapper is licensed under the Apache License 2.0.

## Contributing

Contributions are welcome! Please ensure any changes:
- Maintain backward compatibility
- Include appropriate error handling
- Follow the existing code style
- Are tested on multiple Linux distributions
- Pass shellcheck validation

## Support

For issues or questions:
1. Check the troubleshooting section
2. Run with debug mode (-D) and capture the output
3. Include your Linux distribution and kernel version
4. Provide the output of `lsusb` and `cat /proc/asound/cards`
