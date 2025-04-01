#!/bin/bash
# usb-soundcard-mapper.sh - Automatically map USB sound cards to persistent names
#
# This script automates the process of creating udev rules for USB sound cards
# to ensure they maintain consistent names across reboots.

# Function to print error messages and exit
error_exit() {
    echo -e "\e[31mERROR: $1\e[0m" >&2
    exit 1
}

# Function to print information messages
info() {
    echo -e "\e[34mINFO: $1\e[0m"
}

# Function to print success messages
success() {
    echo -e "\e[32mSUCCESS: $1\e[0m"
}

# Function to print warning messages
warning() {
    echo -e "\e[33mWARNING: $1\e[0m" >&2
}

# Check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root. Please use sudo."
    fi
}

# Function to get available USB sound cards
get_card_info() {
    # Get lsusb output
    info "Getting USB device information..."
    lsusb_output=$(lsusb)
    if [ $? -ne 0 ]; then
        error_exit "Failed to run lsusb command."
    fi
    
    echo "USB devices:"
    echo "$lsusb_output"
    echo
    
    # Get sound card information
    info "Getting sound card information..."
    cards_file="/proc/asound/cards"
    if [ ! -f "$cards_file" ]; then
        error_exit "Cannot access $cards_file. Is ALSA installed properly?"
    fi
    
    cards_output=$(cat "$cards_file")
    if [ $? -ne 0 ]; then
        error_exit "Failed to read $cards_file."
    fi
    
    echo "Sound cards:"
    echo "$cards_output"
    echo
    
    # Display aplay output for reference
    if command -v aplay &> /dev/null; then
        aplay_output=$(aplay -l 2>/dev/null)
        if [ -n "$aplay_output" ]; then
            echo "ALSA playback devices:"
            echo "$aplay_output"
            echo
        fi
    fi
}

# Function to check existing udev rules
check_existing_rules() {
    info "Checking existing udev rules..."
    
    rules_file="/etc/udev/rules.d/99-usb-soundcards.rules"
    
    if [ -f "$rules_file" ]; then
        echo "Existing rules in $rules_file:"
        cat "$rules_file"
        echo
    else
        info "No existing rules file found. A new one will be created."
    fi
}

# Function to reload udev rules
reload_udev_rules() {
    info "Reloading udev rules..."
    
    udevadm control --reload-rules
    if [ $? -ne 0 ]; then
        error_exit "Failed to reload udev rules."
    fi
    
    success "Rules reloaded successfully."
}

# Function to prompt for reboot
prompt_reboot() {
    echo "A reboot is recommended for the changes to take effect."
    read -p "Do you want to reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Rebooting system..."
        reboot
    else
        info "Remember to reboot later for changes to take effect."
    fi
}

# Function to get more detailed card info
get_detailed_card_info() {
    local card_num="$1"
    
    # Get card directory path
    card_dir="/proc/asound/card${card_num}"
    if [ ! -d "$card_dir" ]; then
        error_exit "Cannot find directory $card_dir"
    fi
    
    # Check if it's a USB device
    if [ ! -d "${card_dir}/usbbus" ] && [ ! -d "${card_dir}/usbid" ]; then
        warning "Card $card_num may not be a USB device. Continuing anyway..."
    fi
    
    # Try to get USB info from udevadm
    info "Getting detailed USB information for sound card $card_num..."
    
    # Find a USB device in the card's directory
    device_path=""
    if [ -d "${card_dir}/pcm0p" ]; then
        device_path="${card_dir}/pcm0p/sub0"
    elif [ -d "${card_dir}/pcm0c" ]; then
        device_path="${card_dir}/pcm0c/sub0"
    fi
    
    if [ -n "$device_path" ]; then
        dev_node=$(ls -l "$device_path" | grep -o "/dev/snd/[^ ]*" | head -1)
        if [ -n "$dev_node" ]; then
            info "Using device node: $dev_node"
            udevadm_output=$(udevadm info -a -n "$dev_node" 2>/dev/null)
            echo "$udevadm_output"
            
            # Extract USB bus and device numbers
            bus_num=$(echo "$udevadm_output" | grep -m1 "ATTR{busnum}" | grep -o "[0-9]*$")
            dev_num=$(echo "$udevadm_output" | grep -m1 "ATTR{devnum}" | grep -o "[0-9]*$")
            
            if [ -n "$bus_num" ] && [ -n "$dev_num" ]; then
                info "USB bus:device = $bus_num:$dev_num"
                return 0
            fi
        fi
    fi
    
    info "Detailed USB information retrieval was not successful."
    info "We'll try a different approach..."
    return 1
}

# Interactive mapping function
interactive_mapping() {
    echo -e "\e[1m===== USB Sound Card Mapper =====\e[0m"
    echo "This wizard will guide you through mapping your USB sound card to a consistent name."
    echo
    
    # Get card information
    get_card_info
    
    # Let user select a card by number
    echo "Enter the number of the sound card you want to map:"
    read card_num
    
    if ! [[ "$card_num" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid input. Please enter a number."
    fi
    
    # Get the card information line
    card_line=$(grep -E "^ *$card_num " /proc/asound/cards)
    if [ -z "$card_line" ]; then
        error_exit "No sound card found with number $card_num."
    fi
    
    # Extract card name
    card_name=$(echo "$card_line" | sed -n 's/.*\[\([^]]*\)\].*/\1/p' | xargs)
    if [ -z "$card_name" ]; then
        error_exit "Could not extract card name from line: $card_line"
    fi
    
    echo "Selected card: $card_num - $card_name"
    
    # Try to get detailed card info including USB device path
    get_detailed_card_info "$card_num"
    
    # Let user select USB device
    echo
    echo "Select the USB device that corresponds to this sound card:"
    lsusb | nl -w2 -s". "
    read usb_num
    
    if ! [[ "$usb_num" =~ ^[0-9]+$ ]]; then
        error_exit "Invalid input. Please enter a number."
    fi
    
    # Get the USB device line
    usb_line=$(lsusb | sed -n "${usb_num}p")
    if [ -z "$usb_line" ]; then
        error_exit "No USB device found at position $usb_num."
    fi
    
    # Extract vendor and product IDs
    if [[ "$usb_line" =~ ID\ ([0-9a-f]{4}):([0-9a-f]{4}) ]]; then
        vendor_id="${BASH_REMATCH[1]}"
        product_id="${BASH_REMATCH[2]}"
    else
        error_exit "Could not extract vendor and product IDs from: $usb_line"
    fi
    
    # Extract bus and device numbers for port identification
    if [[ "$usb_line" =~ Bus\ ([0-9]{3})\ Device\ ([0-9]{3}) ]]; then
        bus_num="${BASH_REMATCH[1]}"
        dev_num="${BASH_REMATCH[2]}"
        # Remove leading zeros
        bus_num=$(echo "$bus_num" | sed 's/^0*//')
        dev_num=$(echo "$dev_num" | sed 's/^0*//')
        
        echo "Selected USB device: $usb_line"
        echo "Vendor ID: $vendor_id"
        echo "Product ID: $product_id"
        echo "Bus: $bus_num, Device: $dev_num"
        
        # Use udevadm to get additional info
        usb_path=$(udevadm info -q path -n /dev/bus/usb/$bus_num/$dev_num 2>/dev/null)
        if [ -n "$usb_path" ]; then
            echo "USB path: $usb_path"
        fi
    else
        warning "Could not extract bus and device numbers. This may affect rule creation."
    fi
    
    # Get friendly name from user
    echo
    echo "Enter a friendly name for the sound card (lowercase letters, numbers, and hyphens only):"
    read friendly_name
    
    if [ -z "$friendly_name" ]; then
        friendly_name=$(echo "$card_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        info "Using default name: $friendly_name"
    fi
    
    if ! [[ "$friendly_name" =~ ^[a-z0-9-]+$ ]]; then
        error_exit "Invalid friendly name. Use only lowercase letters, numbers, and hyphens."
    fi
    
    # Check existing rules
    check_existing_rules
    
    # Create the rule
    echo
    echo "Ready to create udev rule. Choose rule type:"
    echo "1. Simple rule (by vendor and product ID only)"
    echo "2. Advanced rule (by vendor, product ID, and USB port path)"
    read rule_type
    
    rules_file="/etc/udev/rules.d/99-usb-soundcards.rules"
    mkdir -p /etc/udev/rules.d/
    
    case "$rule_type" in
        1)
            echo "Creating simple rule..."
            echo "# USB Sound Card: $card_name" >> "$rules_file"
            echo "SUBSYSTEM==\"sound\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{id}=\"$friendly_name\"" >> "$rules_file"
            ;;
        2)
            echo "Creating advanced rule with port matching..."
            if [ -n "$usb_path" ]; then
                echo "# USB Sound Card: $card_name on path $usb_path" >> "$rules_file"
                echo "SUBSYSTEM==\"sound\", KERNELS==\"$usb_path*\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{id}=\"$friendly_name\"" >> "$rules_file"
            else
                warning "USB path not available. Falling back to simple rule."
                echo "# USB Sound Card: $card_name" >> "$rules_file"
                echo "SUBSYSTEM==\"sound\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{id}=\"$friendly_name\"" >> "$rules_file"
            fi
            ;;
        *)
            error_exit "Invalid rule type selection."
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        error_exit "Failed to write to $rules_file."
    fi
    
    # Reload udev rules
    reload_udev_rules
    
    # Prompt for reboot
    prompt_reboot
    
    success "Sound card mapping created successfully."
}

# Non-interactive function
non_interactive_mapping() {
    local device_name="$1"
    local vendor_id="$2"
    local product_id="$3"
    local port="$4"
    local friendly_name="$5"
    
    if [ -z "$device_name" ] || [ -z "$vendor_id" ] || [ -z "$product_id" ] || [ -z "$friendly_name" ]; then
        error_exit "Device name, vendor ID, product ID, and friendly name must be provided for non-interactive mode."
    fi
    
    # Validate inputs
    if ! [[ "$vendor_id" =~ ^[0-9a-f]{4}$ ]]; then
        error_exit "Invalid vendor ID: $vendor_id. Must be a 4-digit hex value."
    fi
    
    if ! [[ "$product_id" =~ ^[0-9a-f]{4}$ ]]; then
        error_exit "Invalid product ID: $product_id. Must be a 4-digit hex value."
    fi
    
    if ! [[ "$friendly_name" =~ ^[a-z0-9-]+$ ]]; then
        error_exit "Invalid friendly name: $friendly_name. Use only lowercase letters, numbers, and hyphens."
    fi
    
    # Create the rule
    info "Creating rule for $device_name..."
    
    rules_file="/etc/udev/rules.d/99-usb-soundcards.rules"
    mkdir -p /etc/udev/rules.d/
    
    # Create or append to rules file
    if [ -z "$port" ]; then
        echo "# USB Sound Card: $device_name" >> "$rules_file"
        echo "SUBSYSTEM==\"sound\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{id}=\"$friendly_name\"" >> "$rules_file"
    else
        echo "# USB Sound Card: $device_name with port $port" >> "$rules_file"
        echo "SUBSYSTEM==\"sound\", KERNELS==\"$port*\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{id}=\"$friendly_name\"" >> "$rules_file"
    fi
    
    if [ $? -ne 0 ]; then
        error_exit "Failed to write to $rules_file."
    fi
    
    # Reload udev rules
    reload_udev_rules
    
    success "Sound card mapping created successfully."
    info "Remember to reboot for changes to take effect."
}

# Display help
show_help() {
    echo "USB Sound Card Mapper - Create persistent names for USB sound devices"
    echo
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --interactive       Run in interactive mode (default)"
    echo "  -n, --non-interactive   Run in non-interactive mode (requires all other parameters)"
    echo "  -d, --device NAME       Device name (for logging only)"
    echo "  -v, --vendor ID         Vendor ID (4-digit hex)"
    echo "  -p, --product ID        Product ID (4-digit hex)"
    echo "  -u, --usb-port PORT     USB port path (optional)"
    echo "  -f, --friendly NAME     Friendly name to assign"
    echo "  -h, --help              Show this help"
    echo
    echo "Examples:"
    echo "  $0                      Run in interactive mode"
    echo "  $0 -n -d \"MOVO X1 MINI\" -v 2e88 -p 4610 -f movo-x1-mini"
    exit 0
}

# Main function
main() {
    check_root
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        interactive_mapping
        exit 0
    fi
    
    local device_name=""
    local vendor_id=""
    local product_id=""
    local port=""
    local friendly_name=""
    local mode="interactive"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -i|--interactive)
                mode="interactive"
                shift
                ;;
            -n|--non-interactive)
                mode="non-interactive"
                shift
                ;;
            -d|--device)
                device_name="$2"
                shift 2
                ;;
            -v|--vendor)
                vendor_id="$2"
                shift 2
                ;;
            -p|--product)
                product_id="$2"
                shift 2
                ;;
            -u|--usb-port)
                port="$2"
                shift 2
                ;;
            -f|--friendly)
                friendly_name="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
    
    if [ "$mode" = "interactive" ]; then
        interactive_mapping
    else
        non_interactive_mapping "$device_name" "$vendor_id" "$product_id" "$port" "$friendly_name"
    fi
}

# Run the main function
main "$@"
