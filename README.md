# udev-audio-mapper

A robust Linux bash script that creates persistent names for USB audio devices, ensuring they maintain the same device name across reboots, even when using multiple identical USB sound cards.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# USB Sound Card Mapper

A robust Linux bash script that creates persistent names for USB audio devices, ensuring they maintain the same device name across reboots, even when using multiple identical USB sound cards.

## Problem Solved

If you use multiple USB audio interfaces on Linux, you've likely encountered these frustrating issues:
- USB sound cards change names (`card0`, `card1`, etc.) after reboots
- Order changes when plugging/unplugging devices
- Identical devices are impossible to distinguish reliably
- Audio applications break when device names change

This script solves these problems by creating udev rules that assign persistent, meaningful names to your USB audio devices based on their physical USB port connection and device attributes.

## Features

- **Interactive wizard** guides you through the mapping process
- **Smart USB port detection** identifies the exact physical port for each device
- **Handles identical devices** by using USB port path information
- **Non-interactive mode** for scripting and automation
- **Testing capability** to verify USB port detection on your system
- **Enhanced reliability** with multiple detection methods
- **Detailed logging** and debug options
- **Robust error handling** to prevent common issues

## Requirements

- Linux system with udev
- Administrator (root) access
- Common Linux utilities: `lsusb`, `udevadm`
- ALSA sound system

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/tomtom215/usb-soundcard-mapper.git
   cd usb-soundcard-mapper
   ```

2. Make the script executable:
   ```bash
   chmod +x usb-soundcard-mapper.sh
   ```

## Usage

### Interactive Mode (Recommended for First-Time Users)

Run the script without arguments to use the interactive wizard:

```bash
sudo ./usb-soundcard-mapper.sh
```

The wizard will:
1. Display all available sound cards
2. Guide you through selecting a card to map
3. Help identify the corresponding USB device
4. Create a persistent mapping rule
5. Reload udev rules

### Non-Interactive Mode (For Automation)

Use command-line arguments for scripting or automation:

```bash
sudo ./usb-soundcard-mapper.sh -n -d "MOVO X1 MINI" -v 2e88 -p 4610 -f movo-x1-mini
```

To include USB port information (recommended for multiple identical devices):

```bash
sudo ./usb-soundcard-mapper.sh -n -d "MOVO X1 MINI" -v 2e88 -p 4610 -u "usb-3.4" -f movo-x1-mini
```

### Test USB Port Detection

Verify that USB port detection works correctly on your system:

```bash
sudo ./usb-soundcard-mapper.sh -t
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-i, --interactive` | Run in interactive mode (default) |
| `-n, --non-interactive` | Run in non-interactive mode |
| `-d, --device NAME` | Device name (for logging only) |
| `-v, --vendor ID` | Vendor ID (4-digit hex) |
| `-p, --product ID` | Product ID (4-digit hex) |
| `-u, --usb-port PORT` | USB port path (for identical devices) |
| `-f, --friendly NAME` | Friendly name to assign |
| `-t, --test` | Test USB port detection |
| `-D, --debug` | Enable debug output |
| `-h, --help` | Show help information |

## How It Works

The script performs these key operations:

1. **Detection**: Identifies USB sound cards in your system using ALSA and USB subsystem info
2. **Port Identification**: Uses multiple methods to determine the physical USB port for each device
3. **Rule Creation**: Generates udev rules that map specific devices to user-defined names
4. **Rule Installation**: Places the rules in `/etc/udev/rules.d/99-usb-soundcards.rules`
5. **Activation**: Reloads udev rules to apply changes

After mapping, your sound card will consistently appear with the specified name regardless of the order devices are connected or system reboots.

## Advanced Port Detection

The script uses several detection methods to achieve high reliability:

1. Direct ALSA information retrieval
2. USB device path analysis through sysfs
3. USB topology examination
4. udevadm information gathering
5. Serial number and device attribute correlation

This multi-layered approach ensures reliable mapping even on systems with complex USB configurations.

## Troubleshooting

### Port Detection Issues

If the port detection test shows failures:

```bash
sudo ./usb-soundcard-mapper.sh -t -D
```

The `-D` flag enables detailed debug output to help identify the issue.

### Rule Verification

To verify that your rules were created correctly:

```bash
cat /etc/udev/rules.d/99-usb-soundcards.rules
```

### Device Listing

List your mapped sound devices:

```bash
aplay -l
```

## Use Cases

- **Audio Production**: Ensure your audio interfaces always connect to the same device names
- **Streaming Setups**: Maintain consistent device names for broadcasting software
- **Multi-Interface Setups**: Reliably identify multiple identical devices
- **Embedded Systems**: Ensure predictable device names in headless applications
- **Automated Installations**: Script the configuration of audio devices


For a deeper technical explanation, see [DOCUMENTATION.md](DOCUMENTATION.md).

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by issues faced by audio professionals and content creators using Linux
- Thanks to the ALSA and udev developers for creating the underlying systems
