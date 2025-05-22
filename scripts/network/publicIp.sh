#!/bin/bash
# This script retrieves and displays the public IP address of the machine
# by querying the ipinfo.io service.

# Ensure curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl to use this script."
    echo "You can typically install it with: sudo pacman -S curl (or your system's package manager)."
    exit 1
fi

# Attempt to fetch the public IP address
# The '-s' flag makes curl silent, suppressing progress meter and error messages.
# If ipinfo.io is down or network is unavailable, this will output nothing or an error.
public_ip=$(curl -s ipinfo.io/ip)

# Check if the IP address was successfully retrieved
if [ -n "$public_ip" ]; then
    echo "Public IP Address: $public_ip"
else
    echo "Error: Could not retrieve public IP address."
    echo "Please check your internet connection and ensure ipinfo.io is accessible."
    exit 1
fi

# Add a newline at the end of the output for better terminal formatting.
echo
