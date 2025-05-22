#!/bin/bash
# This script displays the IPv4 address of a specified or auto-detected network interface.

# Function to display the IPv4 address for a given interface
get_ip_address() {
    local iface="$1"
    # Using 'ip -4 addr show' for IPv4, filtering for 'inet' and the specific interface.
    # awk is used to extract the IP address (e.g., 192.168.1.100/24 -> 192.168.1.100)
    local ip_addr=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+')
    
    if [ -n "$ip_addr" ]; then
        echo "IPv4 address for interface $iface: $ip_addr"
    else
        echo "Error: Could not retrieve IPv4 address for interface $iface, or interface does not have an IPv4 address."
        # List available interfaces that might have IP addresses for user convenience
        echo "Available interfaces with IP addresses:"
        ip -o -4 addr show | awk '{print $2, $4}' | grep -vE 'lo|docker' # Exclude loopback and docker
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

# Get and display the IP address
get_ip_address "$interface_name"
