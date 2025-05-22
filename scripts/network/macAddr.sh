#!/bin/bash
# This script displays the MAC address of a specified or auto-detected network interface.

# Function to display the MAC address for a given interface
get_mac_address() {
    local iface="$1"
    # Using 'ip link show' for the specified interface.
    # awk extracts the MAC address (e.g., link/ether 00:11:22:33:44:55)
    local mac_addr=$(ip link show "$iface" 2>/dev/null | awk '/ether/ {print $2}')
    
    if [ -n "$mac_addr" ]; then
        echo "MAC address for interface $iface: $mac_addr"
    else
        echo "Error: Could not retrieve MAC address for interface $iface, or interface does not exist."
        # List available interfaces for user convenience
        echo "Available interfaces (from ip link):"
        ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | sed 's/://' | grep -vE 'lo|docker'
    fi
}

# Check if an interface name is provided as an argument
if [ -n "$1" ]; then
    interface_name="$1"
    echo "Interface name provided: $interface_name"
else
    # Auto-detect the primary active interface
    echo "No interface name provided. Attempting to auto-detect primary interface..."
    # Using 'ip route get 1.1.1.1' which shows the route via the default interface.
    # awk extracts the interface name (usually the 5th field, e.g., 'dev enp0s3').
    interface_name=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
    
    if [ -n "$interface_name" ]; then
        echo "Auto-detected primary interface: $interface_name"
    else
        echo "Error: Could not auto-detect primary interface."
        echo "Please specify an interface name as an argument."
        echo "Available interfaces (from ip link):"
        ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | sed 's/://' | grep -vE 'lo|docker'
        exit 1
    fi
fi

# Get and display the MAC address
get_mac_address "$interface_name"
