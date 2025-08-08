#!/bin/bash

# Function to display the menu for a given service
show_service_menu() {
    local service_name="$1"
    echo ""
    echo "------------------------------------"
    echo "Managing Service: $service_name"
    echo "------------------------------------"
    echo "1. Status"
    echo "2. Start"
    echo "3. Stop"
    echo "4. Restart"
    echo "5. Enable"
    echo "6. Disable"
    echo "7. Change Service"
    echo "8. Exit"
    echo "------------------------------------"
    read -p "Enter your choice: " choice
}

# Function to execute systemctl command and display result
execute_systemctl_action() {
    local service_name="$1"
    local action="$2"
    local cmd_prefix=""

    echo ""
    echo "Attempting to $action $service_name..."

    # Add sudo for actions that require it
    if [[ "$action" == "start" || "$action" == "stop" || "$action" == "restart" || "$action" == "enable" || "$action" == "disable" ]]; then
        cmd_prefix="sudo "
    fi

    # Execute the command
    if ${cmd_prefix}systemctl "$action" "$service_name"; then
        echo "Successfully executed: $action $service_name"
    else
        echo "Error executing: $action $service_name. Please check the service name and permissions."
    fi
}

# Main script logic
while true; do
    read -p "Enter the name of the service to manage (or type 'exit' to quit): " current_service

    if [[ "$current_service" == "exit" ]]; then
        echo "Exiting."
        break
    fi

    if [[ -z "$current_service" ]]; then
        echo "Service name cannot be empty."
        continue
    fi

    while true; do
        show_service_menu "$current_service"
        case $choice in
            1) execute_systemctl_action "$current_service" "status" ;;
            2) execute_systemctl_action "$current_service" "start" ;;
            3) execute_systemctl_action "$current_service" "stop" ;;
            4) execute_systemctl_action "$current_service" "restart" ;;
            5) execute_systemctl_action "$current_service" "enable" ;;
            6) execute_systemctl_action "$current_service" "disable" ;;
            7) echo "Changing service..."; break ;; # Break inner loop to ask for new service
            8) echo "Exiting."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
        read -p "Press Enter to continue..." # Pause before showing menu again
    done
done
