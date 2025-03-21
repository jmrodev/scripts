#!/bin/bash

# Function to manage service actions
manage_service() {
  local service_name="$1"
  local action="$2"

  # Validate action
  if [[ ! ( "$action" == "start" || "$action" == "stop" || "$action" == "restart" || "$action" == "enable" || "$action" == "disable" ) ]]; then
    echo "Error: Invalid action. Choose from start, stop, restart, enable, or disable."
    exit 1
  fi

  # Determine specific service actions for httpd and mysql
  if [[ "$service_name" == "httpd" ]]; then
    service_name="httpd.service" # Adjust if necessary (e.g., httpd.service)
  elif [[ "$service_name" == "mariadb" ]]; then
    service_name="mariadb"   # Adjust if necessary (e.g., mariadb.service)
  fi

  # Perform action using systemctl
  systemctl "$action" "$service_name" &> /dev/null
  local status_code=$?

  # Display status message based on exit code
  case $status_code in
    0)
      echo "Service '$service_name' successfully $actioned."
      ;;
    1)
      echo "Service '$service_name' is already $(( action == "stop" || action == "disable" ? "stopped" : "started" )) or does not exist."
      ;;
    *)
      echo "Error: Failed to $action service '$service_name' (exit code $status_code)."
      ;;
  esac
}

# Menu for service selection
PS3="Select service: "
select service_name in "httpd" "mariadb" "Exit"; do
  case $REPLY in
    1|2)
      break
      ;;
    3)
      exit 0
      ;;
    *)
      echo "Invalid choice. Please select 1, 2, or 3."
      ;;
  esac
done

# Menu for action selection
PS3="Select action: "
select action in "Start" "Stop" "Restart" "Enable" "Disable" "Exit"; do
  case $REPLY in
    1|2|3|4|5)
      break
      ;;
    6)
      exit 0
      ;;
    *)
      echo "Invalid choice. Please select 1, 2, 3, 4, 5, or 6."
      ;;
  esac
done

# Call the management function with chosen service and action
manage_service "$service_name" "$action"
