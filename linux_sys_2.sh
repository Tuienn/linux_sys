#!/bin/bash

# File: system_manager.sh
# Purpose: A shell script to manage processes, sockets, and network on Ubuntu.
# Author: Grok (based on user requirements)
# Version: 1.0
# Usage: Run as 'system_manager' in terminal after installing to /usr/local/bin/
# Features:
# - Process management: List, kill, change priority, and find processes by name.
# - Socket management: List open sockets, check details, and kill processes by socket.
# - Network management: View configuration, check connectivity, and toggle network.

# Function: show_menu
# Purpose: Display the main menu with hierarchical options for all management tasks.
show_menu() {
    echo "*** System Manager - Menu ***"
    echo "1. Process management"
    echo "    1. List processes"
    echo "    2. Kill a process"
    echo "    3. Change process priority"
    echo "    4. Find processes by name"
    echo "2. Socket management"
    echo "    1. List open sockets"
    echo "    2. Check socket details"
    echo "    3. Kill process by socket"
    echo "3. Network management"
    echo "    1. View network configuration"
    echo "    2. Check connectivity"
    echo "    3. Toggle network"
    echo "4. Exit"
    echo -n "Please enter your choice (e.g., 1.1, 2.1, 3.1, 4): "
}

# Function: list_processes
# Purpose: Display a list of running processes, sorted by CPU usage.
list_processes() {
    # Show top 10 processes by CPU usage
    echo "Listing processes (top 10):"
    ps aux --sort=-%cpu | head -n 11  # ps aux: list all processes; head -n 11: include header
}

# Function: kill_process
# Purpose: Terminate a process by its PID.
kill_process() {
    # Prompt for PID
    echo -n "Enter the PID to kill: "
    read -r pid
    # Validate PID (must be numeric and exist)
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        # Terminate process with SIGKILL (-9)
        sudo kill -9 "$pid"
        if [ $? -eq 0 ]; then
            echo "Process $pid killed successfully."
        else
            echo "Error killing process $pid."
        fi
    else
        echo "Error: Invalid PID."
    fi
}

# Function: change_priority
# Purpose: Change the priority (nice value) of a running process.
change_priority() {
    # Prompt for PID
    echo -n "Enter the PID to change priority: "
    read -r pid
    # Prompt for nice value
    echo -n "Enter new nice value (-20 to 19, lower is higher priority): "
    read -r nice_value
    # Validate PID and nice value
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null && [[ "$nice_value" =~ ^-?[0-9]+$ ]] && [ "$nice_value" -ge -20 ] && [ "$nice_value" -le 19 ]; then
        # Change priority using renice
        sudo renice "$nice_value" -p "$pid"
        if [ $? -eq 0 ]; then
            echo "Priority of process $pid changed to $nice_value."
        else
            echo "Error changing priority."
        fi
    else
        echo "Error: Invalid PID or nice value."
    fi
}

# Function: find_processes_by_name
# Purpose: Find running processes matching a given name.
find_processes_by_name() {
    # Prompt for process name
    echo -n "Enter the process name to find (e.g., firefox, python): "
    read -r name
    # Validate process name
    if [ -z "$name" ]; then
        echo "Error: Process name cannot be empty."
        return 1
    fi
    # Search for processes, case-insensitive, excluding grep itself
    echo "Processes matching '$name':"
    ps aux | grep -i "$name" | grep -v "grep" || echo "No processes found matching '$name'."
}

# Function: list_sockets
# Purpose: Display a list of open TCP and UDP sockets.
list_sockets() {
    # Show listening TCP/UDP sockets
    echo "Listing open TCP/UDP sockets:"
    ss -tuln  # -t: TCP, -u: UDP, -l: listening, -n: numeric addresses
}

# Function: check_socket_details
# Purpose: Display details of processes using a specified port.
check_socket_details() {
    # Prompt for port number
    echo -n "Enter the port number to check: "
    read -r port
    # Validate port number (0-65535)
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 0 ] && [ "$port" -le 65535 ]; then
        # Show processes using the port
        echo "Details for port $port:"
        sudo lsof -i :"$port" || echo "No process using port $port."
    else
        echo "Error: Invalid port number."
    fi
}

# Function: kill_socket_process
# Purpose: Terminate the process using a specified port.
kill_socket_process() {
    # Prompt for port number
    echo -n "Enter the port number to kill process: "
    read -r port
    # Validate port number
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 0 ] && [ "$port" -le 65535 ]; then
        # Get PID of process using the port
        pid=$(sudo lsof -t -i :"$port")
        if [ -n "$pid" ]; then
            # Terminate process with SIGKILL
            sudo kill -9 "$pid"
            if [ $? -eq 0 ]; then
                echo "Process using port $port (PID $pid) killed successfully."
            else
                echo "Error killing process on port $port."
            fi
        else
            echo "No process using port $port."
        fi
    else
        echo "Error: Invalid port number."
    fi
}

# Function: view_network_config
# Purpose: Display current network interface configuration.
view_network_config() {
    # Show network interfaces and their details
    echo "Network configuration:"
    ip addr show
}

# Function: check_connectivity
# Purpose: Test network connectivity by pinging a remote host.
check_connectivity() {
    # Ping google.com 4 times
    echo "Checking connectivity to google.com:"
    ping -c 4 google.com || echo "Connectivity test failed."
}

# Function: toggle_network
# Purpose: Enable or disable network connectivity.
toggle_network() {
    # Prompt for network state
    echo -n "Enable or disable network? (on/off): "
    read -r state
    # Handle enable/disable
    if [ "$state" = "on" ]; then
        # Enable network connectivity
        sudo nmcli networking on
        if [ $? -eq 0 ]; then
            echo "Network enabled."
        else
            echo "Error enabling network."
        fi
    elif [ "$state" = "off" ]; then
        # Disable network connectivity
        sudo nmcli networking off
        if [ $? -eq 0 ]; then
            echo "Network disabled."
        else
            echo "Error disabling network."
        fi
    else
        echo "Invalid choice. Use 'on' or 'off'."
    fi
}

# Main loop
# Purpose: Continuously display menu and handle user input.
while true; do
    # Display main menu
    show_menu
    # Read user choice
    read -r choice
    # Validate input format (x.y or 4)
    if [[ "$choice" =~ ^([1-3])\.([1-4])$ ]] || [[ "$choice" == "4" ]]; then
        main_choice="${BASH_REMATCH[1]}"  # Extract main menu choice
        sub_choice="${BASH_REMATCH[2]}"   # Extract sub-menu choice
        # Handle Exit option
        if [ "$choice" == "4" ]; then
            echo "Exiting program."
            exit 0
        # Handle Process management
        elif [ "$main_choice" == "1" ]; then
            case $sub_choice in
                1)
                    list_processes
                    ;;
                2)
                    kill_process
                    ;;
                3)
                    change_priority
                    ;;
                4)
                    find_processes_by_name
                    ;;
            esac
        # Handle Socket management
        elif [ "$main_choice" == "2" ]; then
            case $sub_choice in
                1)
                    list_sockets
                    ;;
                2)
                    check_socket_details
                    ;;
                3)
                    kill_socket_process
                    ;;
                *)
                    echo "Invalid sub-choice for Socket management. Please try again."
                    ;;
            esac
        # Handle Network management
        elif [ "$main_choice" == "3" ]; then
            case $sub_choice in
                1)
                    view_network_config
                    ;;
                2)
                    check_connectivity
                    ;;
                3)
                    toggle_network
                    ;;
                *)
                    echo "Invalid sub-choice for Network management. Please try again."
                    ;;
            esac
        fi
    else
        # Handle invalid input
        echo "Invalid choice. Please enter a valid option (e.g., 1.1, 2.1, 3.1, 4)."
    fi
    # Add blank line for readability
    echo
done