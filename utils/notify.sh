#!/bin/bash

# Function to manage service actions
manage_service() {
    local service_name="$1"
    local action="$2"

    # Validate action
    # if [[ ! ("$action" == "start" || "$action" == "stop" || "$action" == "restart" || "$action" == "enable" || "$action" == "disable") ]]; then
    #     echo "Error: Invalid action. Choose from start, stop, restart, enable, or disable."
    #     exit 1
    # fi

    # Determine specific service actions for httpd and mysql
    if [[ "$service_name" == "httpd" ]]; then
        service_name="httpd.service" # Adjust if necessary (e.g., httpd.service)
    elif [[ "$service_name" == "mysql" ]]; then
        service_name="mariadb.service" # Adjust if necessary (e.g., mariadb.service)
    fi

    # Perform action using systemctl
    systemctl "$action" "$service_name" &>/dev/null
    local status_code=$?

    # Display status message based on exit code
    case $status_code in
    0)
        echo "Service '$service_name' successfully $action."
        ;;
    1)
        echo "Service '$service_name' is already $((action == "stop" || action == "disable" ? "stopped" : "started")) or does not exist."
        ;;
    *)
        echo "Error: Failed to $action service '$service_name' (exit code $status_code)."
        ;;
    esac
}

# Menu for service selection
PS3="Select service: "
select service_name in "Apache" "Mariadb" "Exit"; do
    case $REPLY in
    1)
        httpd
        ;;
    2)
        mysql
        ;;
    3)
        exit 0
        ;;
    *)
        echo "Invalid choice. Please select 1, 2, or 3."
        ;;
    esac
done

# Translate menu selection to actual action based on REPLY value
action_options=("start" "stop" "restart" "enable" "disable" "Exit")
action="${action_options[$((REPLY - 1))]}" # Adjust REPLY offset if options change

# Call the management function with chosen service and action
manage_service "$service_name" "$action"
