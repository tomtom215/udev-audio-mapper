# USB Audio Mapper

A Linux utility for creating persistent naming rules for USB audio devices, ensuring they maintain consistent names across reboots.

## Overview

USB Audio Mapper creates udev rules to persistently name your USB audio devices in Linux. This solves the common issue where USB audio devices may change names (card0, card1, etc.) when other devices are connected or after reboots, causing configuration and application problems.

## Features

- Creates comprehensive udev rules for reliable device identification
- Provides persistent device names and symlinks for easy access
- Handles multiple identical devices correctly by detecting physical USB ports
- Supports both interactive and non-interactive operation
- Detects device vendor/product IDs, USB paths, and platform-specific paths
- Works across different Linux distributions with varying device path formats

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

USB Audio Mapper solves these issues by creating persistent, reliable device names and paths that remain consistent regardless of connection order or system changes.

## Installation

1. Download the script:
   ```bash
   wget https://github.com/tomtom215/usb_audio_mapper.sh
   ```

2. Make it executable:
   ```bash
   chmod +x usb_audio_mapper.sh
   ```

## Usage

### Interactive Mode

Run the script with no arguments to enter interactive mode:

```bash
sudo ./usb_audio_mapper.sh
```

Follow the prompts to:
1. Select a sound card from the detected USB audio devices
2. Confirm the corresponding USB device
3. Enter a friendly name for the device (lowercase letters, numbers, and hyphens only)
4. Optionally reboot to apply the changes

### Non-Interactive Mode

For scripting or automating device naming:

```bash
sudo ./usb_audio_mapper.sh -n -d "DEVICE_NAME" -v VENDOR_ID -p PRODUCT_ID -f FRIENDLY_NAME
```

Required parameters:
- `-d` : Device name (descriptive, for logging only)
- `-v` : Vendor ID (4-digit hex)
- `-p` : Product ID (4-digit hex)
- `-f` : Friendly name (will be used in device paths)

Optional parameters:
- `-u` : USB port path (helps with multiple identical devices)

Example:
```bash
sudo ./usb_audio_mapper.sh -n -d "MOVO X1 MINI" -v 2e88 -p 4610 -f movo-mic
```

### Additional Options

- `-t, --test` : Test USB port detection only
- `-D, --debug` : Enable debug output for troubleshooting
- `-h, --help` : Display help information

## Validation

After running the script and rebooting, verify the mapping worked by:

1. Checking the sound card list:
   ```bash
   cat /proc/asound/cards
   ```
   Your device should appear with the friendly name you chose.

2. Listing ALSA devices:
   ```bash
   arecord -l  # For input devices
   aplay -l    # For output devices
   ```

3. Verifying the udev rules:
   ```bash
   sudo cat /etc/udev/rules.d/99-usb-soundcards.rules
   ```
   Should show three rule types for your device.

4. Checking the symlink was created:
   ```bash
   ls -la /dev/sound/by-id/
   ```
   Should show a symlink with your friendly name.

## Troubleshooting

### Device Not Being Renamed

1. Check the udev rules were created:
   ```bash
   sudo cat /etc/udev/rules.d/99-usb-soundcards.rules
   ```

2. Reload the udev rules manually:
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. Verify the device information matches your actual device:
   ```bash
   lsusb
   ```
   Check that the vendor and product IDs in the rule match the actual device.

4. Run the script with debug logging:
   ```bash
   sudo ./usb_audio_mapper.sh -D
   ```

### Multiple Identical Devices

If you have multiple identical USB audio devices:

1. Run the script in interactive mode for each device
2. Physically connect devices one at a time and run the script for each
3. Use the `-u` option with the USB port path when running in non-interactive mode

### Path Identification Issues

For more complex setups or problematic devices:

1. Test port detection capability:
   ```bash
   sudo ./usb_audio_mapper.sh -t
   ```

2. Get detailed device information and check sysfs paths:
   ```bash
   sudo udevadm info -a -n /dev/snd/controlC0
   ```
   (Replace `controlC0` with your device number)

3. Monitor udev events when plugging in the device:
   ```bash
   sudo udevadm monitor --environment
   ```

## Uninstallation

To remove the persistent naming rules:

1. Delete the udev rules file:
   ```bash
   sudo rm /etc/udev/rules.d/99-usb-soundcards.rules
   ```

2. Reload udev rules:
   ```bash
   sudo udevadm control --reload-rules
   ```

3. Reboot to restore default device naming:
   ```bash
   sudo reboot
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
   - Uses the ATTRS{} operator which searches up the device chain (parent devices)
   - Provides a baseline match for the device type

2. **USB Path rule**:
   ```
   SUBSYSTEM=="sound", KERNELS=="usb-X.Y", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="sound/by-id/friendly-name", ATTR{id}="friendly-name"
   ```
   - KERNELS matches against the device path in the kernel
   - Includes the physical USB port information (X.Y represents port numbers)
   - Can distinguish between identical devices in different USB ports

3. **Platform Path rule**:
   ```
   SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-controller-usb-0:X.Y:1.0", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="sound/by-id/friendly-name", ATTR{id}="friendly-name"
   ```
   - Uses ENV{ID_PATH} which contains a complete platform-specific path
   - Provides the most specific matching for the exact hardware path
   - Works reliably even with complex USB topologies (hubs, etc.)

### Actions and Persistence

When a rule matches, it performs two key actions:

1. **ATTR{id}="friendly-name"** - This sets the ALSA card ID, which is what appears in `/proc/asound/cards` and is used by ALSA applications.

2. **SYMLINK+="sound/by-id/friendly-name"** - This creates a persistent symlink in `/dev/sound/by-id/` pointing to the actual device node, providing a stable path for applications to use.

These settings persist across reboots because:
- The rules file is stored in `/etc/udev/rules.d/` which survives reboots
- Every time the device is connected, udev processes these rules again
- The same friendly name is always assigned regardless of when the device is detected

### Rule Storage and System Integration

The rules are stored in `/etc/udev/rules.d/99-usb-soundcards.rules`, which is part of the system configuration that persists across reboots. When the system starts up or when devices are hot-plugged:

1. The kernel detects hardware and creates uevent messages
2. udevd (the udev daemon) receives these events
3. udevd processes all rules, including our custom rules
4. Matching devices are named according to our rules before applications access them

This ensures that no matter when the sound card is connected, it always gets the same consistent name and symlink.

## Use Cases

The USB Audio Mapper is particularly useful in the following scenarios:

### Professional Audio Production

- **Recording Studios**: When using multiple audio interfaces in professional environments where consistent routing is critical
- **Live Performance**: For musicians using Linux-based systems where audio devices must maintain the same configuration between shows
- **Podcasting/Streaming**: Ensuring microphones and mixers maintain consistent device names across recording sessions

### Multi-Device Setups

- **Multiple Identical Devices**: When using several identical USB microphones or interfaces that would otherwise be indistinguishable
- **Complex Audio Routing**: For setups with multiple input and output devices that need stable device paths
- **Video Conferencing Systems**: Ensuring the correct microphone is always used regardless of connection order

### Automated Systems

- **Kiosks & Digital Signage**: Systems that must reliably use specific audio hardware after reboots
- **Unattended Systems**: Servers or appliances that need to automatically recognize the correct audio devices
- **Embedded Applications**: Industrial control systems or information kiosks with specific audio hardware requirements

### Development and Testing

- **Audio Software Development**: When developing applications that interact with audio hardware
- **Hardware Testing**: For QA environments that test multiple audio devices
- **Continuous Integration**: Systems that run automated tests on audio equipment

### Educational and Shared Environments

- **Computer Labs**: Where multiple identical workstations must maintain the same device configuration
- **Shared Workstations**: In environments where different users connect various audio devices
- **Classroom Recording**: Ensuring consistent audio device naming in educational recording setups

### Home and Specialized Uses

- **HTPC/Media Centers**: Home theater PCs that need reliable audio device mapping
- **Gaming Setups**: When using specific audio devices for gaming that shouldn't change between sessions
- **Accessibility Solutions**: Systems configured for users with disabilities that rely on specific audio routing
- **Raspberry Pi Projects**: Small form-factor computers using USB audio where consistent naming is critical

### System Administration

- **Remote Administration**: Simplifying the management of audio devices on remotely administered systems
- **Hardware Deployment**: Creating consistent configurations across multiple deployed systems
- **Device Monitoring**: Creating stable device paths for monitoring systems to track

## License

USB Audio Mapper is licensed under the Apache License 2.0.
