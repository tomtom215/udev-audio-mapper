# udev-audio-mapper - Technical Documentation

This document provides detailed technical information about how the udev-audio-mapper works, the underlying Linux subsystems it interacts with, and how to customize it for advanced use cases.

## Table of Contents

1. [Understanding Linux Audio and USB Devices](#understanding-linux-audio-and-usb-devices)
2. [How udev Works](#how-udev-works)
3. [Script Internals](#script-internals)
4. [Rule Creation Logic](#rule-creation-logic)
5. [Advanced Usage Scenarios](#advanced-usage-scenarios)
6. [Customizing Rules](#customizing-rules)
7. [Technical Limitations](#technical-limitations)
8. [Debugging Techniques](#debugging-techniques)
9. [FAQs](#faqs)

## Understanding Linux Audio and USB Devices

### ALSA Sound System

The Advanced Linux Sound Architecture (ALSA) provides audio functionality to the Linux kernel. USB audio devices appear in the system as ALSA sound cards.

- Sound cards are enumerated in `/proc/asound/cards`
- Each card gets a number (e.g., `0`, `1`, `2`) and a string identifier
- By default, these numbers can change when devices are connected in different orders

### USB Device Detection

USB devices in Linux:
- Are detected and managed by the kernel's USB subsystem
- Have unique vendor and product IDs (VIDs and PIDs)
- Connect to specific physical ports which have a topology
- Are exposed through sysfs at `/sys/bus/usb/devices/`

### The Problem of Changing Device Names

When you connect multiple USB audio interfaces:
1. They get assigned card numbers based on detection order
2. These numbers can change depending on:
   - Which order you plug them in
   - Which USB ports you use
   - When you boot your computer
3. This breaks applications configured to use specific card numbers

## How udev Works

### The udev System

udev is Linux's device manager that:
- Creates device nodes in `/dev`
- Handles hotplug events when devices connect/disconnect
- Runs rules to set attributes and symlinks for devices
- Ensures persistent naming across reboots

### Rule Structure

A typical udev rule:
```
SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="my-interface"
```

Components:
- **Match keys** (left of `==`): Match device attributes
- **Assignment keys** (left of `=`): Set device attributes
- **Operators**: `==` (match), `=` (assign), `+=` (append), etc.

### How Rules Are Processed

1. When a device is connected, udev checks all rules
2. Rules are processed in lexical order by filename
3. All matching rules will be applied (not just the first match)
4. Processing stops for a key once it has been assigned

### Rule Files Location

- System rules: `/usr/lib/udev/rules.d/`
- Custom rules: `/etc/udev/rules.d/` (takes precedence)
- Our script creates: `/etc/udev/rules.d/99-usb-soundcards.rules`

## Script Internals

### Main Components

The script consists of these primary functions:

1. `get_card_info()`: Retrieves information about USB devices and sound cards
2. `get_detailed_card_info()`: Gets detailed USB information for a specific sound card
3. `interactive_mapping()`: Interactive wizard interface
4. `non_interactive_mapping()`: Command-line automation interface
5. `check_existing_rules()`: Examines existing udev rules
6. `reload_udev_rules()`: Applies changes to udev

### Data Flow

The script follows this general workflow:

1. Get information about all sound cards and USB devices
2. Identify which USB device corresponds to which sound card
3. Extract unique identifiers (vendor ID, product ID, USB path)
4. Generate a udev rule based on these identifiers
5. Write the rule to the filesystem
6. Reload udev rules to apply changes

## Rule Creation Logic

### Simple Rules vs. Advanced Rules

#### Simple Rule
```
SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="my-interface"
```

- Matches any sound device with the specified VID/PID
- Good for when you only have one of each device type
- Will match the same device model connected to any port

#### Advanced Rule
```
SUBSYSTEM=="sound", KERNELS=="3-1.2*", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="my-interface"
```

- Includes USB topology path (e.g., `3-1.2`)
- Ensures the name is tied to both the device type AND the specific USB port
- Good for multiple identical devices

### Attribute Selection Logic

The script uses:
- `SUBSYSTEM=="sound"` to target only audio devices
- `ATTRS{idVendor}` and `ATTRS{idProduct}` from lsusb output
- `KERNELS` pattern matching for USB topology paths
- `ATTR{id}` to set the persistent name

## Advanced Usage Scenarios

### Multiple Identical Interfaces

If you have multiple identical interfaces (e.g., two Focusrite Scarlett 2i2s):

1. Use the advanced rule type
2. Map each one separately, choosing different friendly names
3. Always connect them to the same physical USB ports

### Audio Interface Arrays

For complex setups with many interfaces:

1. Create a consistent naming scheme (e.g., `interface-1`, `interface-2`)
2. Use physical USB port labels or tape to mark which device goes where
3. Consider creating a shell script using non-interactive mode to set up all devices at once

### Integration with Audio Software

For audio software that uses ALSA directly:
- Device will appear with your chosen name in the device list
- Configuration files may need to be updated to use new names

For JACK or PulseAudio:
- The persistent name ensures consistent device ordering
- Configuration files should be updated after mapping

## Customizing Rules

### Manual Rule Editing

You can manually edit `/etc/udev/rules.d/99-usb-soundcards.rules` to:
- Add comments for clarity
- Adjust matching parameters
- Use additional udev capabilities

Example of a customized rule:
```
# My studio interface
SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="studio-main", GROUP="audio", MODE="0660"
```

### Adding Additional Attributes

Beyond just renaming, you can add:
- `GROUP="audio"`: Set the device group
- `MODE="0660"`: Set file permissions
- `SYMLINK+="sound/by-purpose/main-interface"`: Create additional symlinks

### Running Commands When Devices Connect

Add actions with `RUN+=`:
```
SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", ATTR{id}="studio-main", RUN+="/usr/local/bin/notify-audio-connected.sh"
```

## Technical Limitations

### Hardware Limitations

- Some USB hubs may not correctly report topology information
- Virtual machines may have inconsistent USB device reporting
- USB audio class compliance varies between manufacturers

### Software Limitations

- Relies on udev which is specific to Linux (won't work on other operating systems)
- Requires reboot or device reconnection for changes to take effect
- Can be overridden by other udev rules with higher priority

### Edge Cases

- Devices that change their descriptors based on configuration
- USB audio interfaces that present multiple sound cards
- Device firmware updates that change VID/PID

## Debugging Techniques

### Checking Current Device Information

```bash
# List sound cards
cat /proc/asound/cards

# List USB devices
lsusb

# Get detailed info about a USB device
lsusb -v -d 1235:8210

# Find device nodes
ls -l /dev/snd/
```

### Testing udev Rules

```bash
# Test how a rule would match without applying it
udevadm test $(udevadm info -q path -n /dev/snd/controlC0)

# Watch udev events in real-time
udevadm monitor --environment

# Check detailed information about a device
udevadm info --attribute-walk --name=/dev/snd/controlC0
```

### Common Debugging Steps

1. Verify the device is detected:
   ```bash
   lsusb | grep <vendor ID>
   ```

2. Verify sound card is detected:
   ```bash
   cat /proc/asound/cards | grep <device name>
   ```

3. Check rule syntax:
   ```bash
   udevadm verify /etc/udev/rules.d/99-usb-soundcards.rules
   ```

4. Test the rule:
   ```bash
   udevadm test $(udevadm info -q path -n /dev/snd/controlC0)
   ```

5. Reload rules and reconnect the device:
   ```bash
   sudo udevadm control --reload-rules
   # Physically disconnect and reconnect device
   ```

## FAQs

### Q: How can I remove a rule for a specific device?

A: Edit `/etc/udev/rules.d/99-usb-soundcards.rules` and remove the line(s) corresponding to your device. Then reload udev rules:
```bash
sudo udevadm control --reload-rules
```

### Q: Will this work with all USB audio interfaces?

A: It should work with most USB audio interfaces that appear as ALSA sound cards. Some very unusual or non-compliant devices might not work properly.

### Q: Can I use this for other types of devices, not just audio?

A: The principle is the same, but you would need to modify the script to match against different subsystems and attributes.

### Q: What happens if I use the same friendly name for two different devices?

A: The last rule processed will win, and both devices will try to use the same name, which could cause conflicts. Always use unique friendly names.

### Q: Does this affect PulseAudio or JACK?

A: PulseAudio and JACK sit on top of ALSA, so they will see the renamed devices. This can make their configuration more consistent.

### Q: Will my settings persist after a system update?

A: Yes, since the rules are stored in `/etc/udev/rules.d/`, they will survive system updates. However, a full system reinstall would require recreating the rules.
