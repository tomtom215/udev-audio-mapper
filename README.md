# udev-audio-mapper

A tool to create persistent device names for USB audio interfaces in Linux using udev rules.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

![Linux USB Audio Mapper](https://raw.githubusercontent.com/username/linux-usb-audio-mapper/main/images/banner.png)

## Why Use This?

If you've ever connected multiple USB audio interfaces to your Linux system, you've probably encountered this problem: **the order of your sound cards changes when you reboot or reconnect devices**. This can break your audio configurations and frustrate your workflow.

This script solves that problem by creating udev rules that give your USB audio devices persistent names, ensuring they always appear with the same name regardless of connection order.

## Features

- **Interactive wizard** guides you through the mapping process
- **Persistent naming** for all your USB audio devices
- **Advanced detection** of USB devices and sound cards
- **Multiple rule types** to handle different use cases
- **Non-interactive mode** for scripting and automation

## Requirements

- Linux system with udev (all modern distributions)
- Root access (for creating udev rules)
- ALSA sound system
- `lsusb` command (usually pre-installed)
- `udevadm` command (usually pre-installed)

## Installation

### Quick Install

```bash
git clone https://github.com/username/udev-audio-mapper.git
cd udev-audio-mapper
chmod +x usb-soundcard-mapper.sh
```

### Manual Install

1. Download the script:
```bash
wget https://raw.githubusercontent.com/username/udev-audio-mapper/main/usb-soundcard-mapper.sh
```

2. Make it executable:
```bash
chmod +x usb-soundcard-mapper.sh
```

## Usage

### Interactive Mode (recommended for most users)

Run the script without arguments to use the interactive wizard:

```bash
sudo ./usb-soundcard-mapper.sh
```

The wizard will:
1. List all sound cards and USB devices
2. Let you select which sound card to map
3. Let you select the corresponding USB device
4. Allow you to choose a friendly name
5. Offer a choice between simple and advanced rules
6. Create the udev rule

### Non-Interactive Mode

For scripting or automation, use the non-interactive mode:

```bash
sudo ./usb-soundcard-mapper.sh -n -d "Device Name" -v vendor_id -p product_id -f friendly_name
```

Parameters:
- `-n` or `--non-interactive`: Run in non-interactive mode
- `-d` or `--device`: Name of the device (for logging only)
- `-v` or `--vendor`: Vendor ID (4-digit hex)
- `-p` or `--product`: Product ID (4-digit hex)
- `-u` or `--usb-port`: USB port path (optional, for advanced rules)
- `-f` or `--friendly`: Friendly name to assign to the device
- `-h` or `--help`: Show help message

Example:
```bash
sudo ./usb-soundcard-mapper.sh -n -d "Focusrite Scarlett 2i2" -v 1235 -p 8210 -f scarlett-2i2
```

## Rule Types

### Simple Rule

Uses only vendor and product IDs. Good for:
- Single instances of each device type
- Devices that are always connected to the same system

Example:
```
SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="scarlett-2i2"
```

### Advanced Rule

Includes USB path information. Good for:
- Multiple instances of the same device type
- Maintaining association with specific USB ports

Example:
```
SUBSYSTEM=="sound", KERNELS=="3-1.2*", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="scarlett-2i2"
```

## Troubleshooting

### Rule Not Working?

1. Verify the rule was created:
```bash
cat /etc/udev/rules.d/99-usb-soundcards.rules
```

2. Check if your device is recognized:
```bash
lsusb
```

3. Reload udev rules and reconnect your device:
```bash
sudo udevadm control --reload-rules
# Disconnect and reconnect your device
```

4. Check sound card list:
```bash
cat /proc/asound/cards
```

### Common Issues

- **Device Name Not Changing**: Make sure you've rebooted or reconnected the device after creating the rule.
  
- **Multiple Devices with Same Name**: Try using the advanced rule type which includes USB port information.

- **Rule Conflicts**: Check for other rules in `/etc/udev/rules.d/` that might target the same devices.

## How It Works

1. **Device Detection**: The script detects USB audio devices using information from `/proc/asound/cards` and `lsusb`.

2. **Rule Creation**: Based on your choices, it creates a udev rule that matches your device using various attributes.

3. **Rule Activation**: The script reloads udev rules, which will take effect when you reconnect the device or reboot.

For a deeper technical explanation, see [DOCUMENTATION.md](docs/DOCUMENTATION.md).

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by issues faced by audio professionals and content creators using Linux
- Thanks to the ALSA and udev developers for creating the underlying systems
