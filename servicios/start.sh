#!/bin/bash

# Check if services were provided as arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 service1 [service2 service3 ...]"
    exit 1
fi

# Start the services passed as arguments
pkexec systemctl start "$@"

# Check if services started successfully
if [ $? -eq 0 ]; then
    # Display a notification indicating that services have started successfully
    notify-send "Services Started" "The services have started successfully."

    # Wait for a moment to allow services to stabilize
    sleep 2

    # Check the status of each service and display its state
    for service in "$@"; do
        status=$(sudo systemctl is-active $service)
        notify-send "Service Status: $service" "The service $service is currently $status"
    done
else
    # Display an error message if services could not be started
    notify-send "Error Starting Services" "There was a problem starting the services: $@"
fi
