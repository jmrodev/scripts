#!/bin/bash
# This script extracts open ports and an IP address from a given Nmap scan output file.
# It then prints this information and attempts to copy the ports to the clipboard.

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "Usage: $0 <nmap_output_file>"
    echo "Please provide the path to an Nmap scan output file."
    exit 1
fi

input_file="$1"

if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

# --- Temporary File Setup and Cleanup ---
# Create a temporary file using mktemp
# The 'XXXXXX' will be replaced by mktemp to ensure a unique filename.
temp_file=$(mktemp /tmp/extractPorts.XXXXXX)

# Setup a trap to ensure the temporary file is cleaned up when the script exits,
# regardless of whether it exits normally or due to an error (SIGINT, SIGTERM, ERR).
trap 'rm -f "$temp_file"' EXIT SIGINT SIGTERM ERR

# --- Data Extraction ---
# Extract open ports (e.g., "80/open", "443/open") and format them as a comma-separated list.
# grep -oP: Only print the matching part (-o) using Perl-compatible regex (-P).
# awk '{print $1}' FS='/': Print the first field (port number) using '/' as a delimiter.
# xargs: Convert the list of ports (separated by newlines) into a single line.
# tr ' ' ',': Replace spaces with commas.
ports=$(grep -oP '\d{1,5}/open' "$input_file" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

# Extract the first unique IP address found in the file.
# grep -oP: Similar to above, but for an IPv4 address pattern.
# sort -u: Sort and keep only unique IP addresses.
# head -n 1: Take the first IP address from the unique list.
ip_address=$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$input_file" | sort -u | head -n 1)

# --- Output Preparation ---
# Store the extracted information in the temporary file for organized output.
echo -e "\n[*] Extracting information from: $input_file\n" > "$temp_file"

if [ -n "$ip_address" ]; then
    echo -e "\t[*] IP Address: $ip_address" >> "$temp_file"
else
    echo -e "\t[*] IP Address: Not found in file." >> "$temp_file"
fi

if [ -n "$ports" ]; then
    echo -e "\t[*] Open ports: $ports\n" >> "$temp_file"
else
    echo -e "\t[*] Open ports: No open ports found matching the pattern.\n" >> "$temp_file"
fi

# --- Clipboard Handling ---
# Check if xclip is installed
if command -v xclip &> /dev/null; then
    if [ -n "$ports" ]; then
        # Copy the comma-separated port list to the clipboard
        echo "$ports" | tr -d '\n' | xclip -selection clipboard
        echo -e "[*] Ports ('$ports') copied to clipboard.\n" >> "$temp_file"
    else
        echo -e "[*] No ports to copy to clipboard.\n" >> "$temp_file"
    fi
else
    echo -e "[*] xclip is not installed. Ports cannot be copied to clipboard automatically." >> "$temp_file"
    echo -e "    You can install it with: sudo pacman -S xclip (or your system's package manager)\n" >> "$temp_file"
fi

# --- Final Output ---
# Display the content of the temporary file
cat "$temp_file"

# The trap will automatically remove $temp_file upon script exit.
# Explicitly exiting successfully.
exit 0
