#!/bin/bash

# File: file_manager.sh
# Purpose: A shell script to manage files, schedule tasks, set system time, and manage packages on Ubuntu.
# Author: Grok (based on user requirements)
# Version: 1.0
# Usage: Run as 'file_manager' in terminal after installing to /usr/local/bin/
# Features:
# - File management: Create, delete, move, and check file information.
# - Schedule tasks: Create, list, and delete cron jobs.
# - System time setup: View time, set timezone, toggle NTP synchronization.
# - Package management: Install (apt, snap, flatpak) and remove packages.

# Function: process_path
# Purpose: Process user input to generate a full file path based on input type.
# Input: $1 - User-provided file name or path (e.g., "file.txt", "subdir/file.txt", "/absolute/path").
# Output: Echoes the full path (relative or absolute).
process_path() {
    local input="$1"  # Store input argument
    if [[ "$input" != */* ]]; then
        # Input is a simple filename (no slashes), prepend current directory
        echo "$(pwd)/$input"
    elif [[ "$input" != /* ]]; then
        # Input is a relative path (no leading slash), create subdirectories if needed
        local dir=$(dirname "$input")  # Extract directory part
        mkdir -p "$(pwd)/$dir"  # Create directories if they don't exist
        echo "$(pwd)/$input"  # Prepend current directory to path
    else
        # Input is an absolute path (starts with /), use as is
        echo "$input"
    fi
}

# Function: show_menu
# Purpose: Display the main menu with hierarchical options for all management tasks.
show_menu() {
    echo "*** Process Management - Menu ***"
    echo "1. File management"
    echo "    1. Create file"
    echo "    2. Delete file"
    echo "    3. Move file"
    echo "    4. Check file information"
    echo "2. Schedule tasks"
    echo "    1. Create a task"
    echo "    2. List tasks"
    echo "    3. Delete a task"
    echo "3. System time setup"
    echo "    1. View time information"
    echo "    2. Set timezone"
    echo "    3. Toggle NTP synchronization"
    echo "4. Package management"
    echo "    1. Install a package"
    echo "    2. Remove a package"
    echo "5. Exit"
    echo -n "Please enter your choice (e.g., 1.1, 2.1, 3.1, 4.1, 5): "
}

# Function: install_apt
# Purpose: Install or update a package using apt.
# Input: $1 - Package name (e.g., "vim").
install_apt() {
    local package="$1"  # Store package name
    # Update package list to ensure latest versions
    sudo apt update
    # Install or update package, -y auto-confirms
    sudo apt install "$package" -y
    if [ $? -eq 0 ]; then
        echo "Package '$package' installed or updated successfully via apt."
    else
        echo "Error installing or updating package '$package' via apt."
    fi
}

# Function: install_snap
# Purpose: Install a package using snap.
# Input: $1 - Package name (e.g., "spotify").
install_snap() {
    local package="$1"  # Store package name
    # Install package using snap
    sudo snap install "$package"
    if [ $? -eq 0 ]; then
        echo "Package '$package' installed successfully via snap."
    else
        echo "Error installing package '$package' via snap."
    fi
}

# Function: install_flatpak
# Purpose: Install a package using flatpak, installing flatpak if not present.
# Input: $1 - Package name (e.g., "org.gimp.GIMP").
install_flatpak() {
    local package="$1"  # Store package name
    # Check if flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        echo "Flatpak is not installed. Installing flatpak..."
        # Install flatpak using apt
        sudo apt update
        sudo apt install flatpak -y
        if [ $? -ne 0 ]; then
            echo "Error installing flatpak."
            return 1
        fi
        # Add Flathub repository for flatpak packages
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    # Install package from Flathub, -y auto-confirms
    flatpak install flathub "$package" -y
    if [ $? -eq 0 ]; then
        echo "Package '$package' installed successfully via flatpak."
    else
        echo "Error installing package '$package' via flatpak."
    fi
}

# Function: install_package
# Purpose: Allow user to install a package using apt, snap, or flatpak.
install_package() {
    # Display installation method menu
    echo "Install a package:"
    echo "1. Using apt"
    echo "2. Using snap"
    echo "3. Using flatpak"
    echo -n "Choose an installation method (1-3): "
    read -r method
    # Prompt for package name
    echo -n "Enter the package name (e.g., vim, spotify, org.gimp.GIMP): "
    read -r package
    # Validate package name
    if [ -z "$package" ]; then
        echo "Error: Package name cannot be empty."
        return 1
    fi
    # Call appropriate installation function based on method
    case $method in
        1)
            install_apt "$package"
            ;;
        2)
            install_snap "$package"
            ;;
        3)
            install_flatpak "$package"
            ;;
        *)
            echo "Invalid installation method. Please choose 1, 2, or 3."
            ;;
    esac
}

# Function: remove_package
# Purpose: Remove a package using apt, with option to purge configuration files.
remove_package() {
    # Prompt for package name
    echo -n "Enter the package name to remove (e.g., vim, curl): "
    read -r package
    # Validate package name
    if [ -z "$package" ]; then
        echo "Error: Package name cannot be empty."
        return 1
    fi
    # Check if package is installed
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "Package '$package' is not installed."
        return 0
    fi
    # Ask if user wants to purge configuration files
    echo -n "Remove configuration files as well (purge)? (y/n): "
    read -r purge
    if [[ "$purge" == "y" || "$purge" == "Y" ]]; then
        # Purge package (remove program and config files)
        sudo apt purge "$package" -y
        if [ $? -eq 0 ]; then
            echo "Package '$package' purged successfully."
        else
            echo "Error purging package '$package'."
        fi
    else
        # Remove package (keep config files)
        sudo apt remove "$package" -y
        if [ $? -eq 0 ]; then
            echo "Package '$package' removed successfully."
        else
            echo "Error removing package '$package'."
        fi
    fi
}

# Function: create_file
# Purpose: Create a new file, optionally with content using nano editor.
create_file() {
    # Prompt for file name or path
    echo -n "Enter the file name or path (e.g., file.txt, subdir/file.txt, /absolute/path/file.txt): "
    read -r input
    # Generate full path using process_path
    full_path=$(process_path "$input")
    # Validate path
    if [ -z "$full_path" ]; then
        echo "Error: Invalid path."
        return 1
    fi
    # Check write permission for directory
    local dir=$(dirname "$full_path")
    if [ ! -w "$dir" ]; then
        echo "Error: No write permission in directory '$dir'."
        return 1
    fi
    # Ask if user wants to add content
    echo -n "Do you want to add content to the file? (y/n): "
    read -r add_content
    if [[ "$add_content" == "y" || "$add_content" == "Y" ]]; then
        # Open nano editor to add content
        nano "$full_path"
    else
        # Create empty file
        touch "$full_path"
    fi
    # Check if file creation was successful
    if [ $? -eq 0 ]; then
        echo "File '$full_path' created successfully."
    else
        echo "Error creating file '$full_path'."
    fi
}

# Function: delete_file
# Purpose: Delete a specified file.
delete_file() {
    # Prompt for file name or path
    echo -n "Enter the file name or path to delete (e.g., file.txt, subdir/file.txt, /absolute/path/file.txt): "
    read -r input
    # Generate full path
    full_path=$(process_path "$input")
    # Validate path
    if [ -z "$full_path" ]; then
        echo "Error: Invalid path."
        return 1
    fi
    # Check if file exists
    if [ -e "$full_path" ]; then
        # Delete file forcefully (-f ignores errors)
        rm -f "$full_path"
        if [ $? -eq 0 ]; then
            echo "File '$full_path' deleted successfully."
        else
            echo "Error deleting file '$full_path'."
        fi
    else
        echo "File '$full_path' does not exist."
    fi
}

# Function: move_file
# Purpose: Move a file from source to destination.
move_file() {
    # Prompt for source file/path
    echo -n "Enter the source file name or path (e.g., file.txt, subdir/file.txt, /absolute/path/file.txt): "
    read -r source_input
    # Generate source full path
    source_path=$(process_path "$source_input")
    # Validate source path
    if [ -z "$source_path" ]; then
        echo "Error: Invalid source path."
        return 1
    fi
    # Prompt for destination
    echo -n "Enter the destination (directory or new file path, e.g., dest_dir/, dest_dir/file.txt, /absolute/path/): "
    read -r dest_input
    # Handle destination as directory or file path
    if [[ "$dest_input" == */ ]]; then
        # Destination is a directory, append source filename
        local filename=$(basename "$source_path")
        dest_path=$(process_path "${dest_input}${filename}")
    else
        # Destination is a file path
        dest_path=$(process_path "$dest_input")
    fi
    # Validate destination path
    if [ -z "$dest_path" ]; then
        echo "Error: Invalid destination path."
        return 1
    fi
    # Check write permission for destination directory
    local dir=$(dirname "$dest_path")
    if [ ! -w "$dir" ]; then
        echo "Error: No write permission in destination directory '$dir'."
        return 1
    fi
    # Move file forcefully (-f overwrites if exists)
    mv -f "$source_path" "$dest_path"
    if [ $? -eq 0 ]; then
        echo "File '$source_path' moved to '$dest_path' successfully."
    else
        echo "Error moving file '$source_path'."
    fi
}

# Function: check_file_info
# Purpose: Display detailed information about a file.
check_file_info() {
    # Prompt for file name or path
    echo -n "Enter the file name or path to check (e.g., file.txt, subdir/file.txt, /absolute/path/file.txt): "
    read -r input
    # Generate full path
    full_path=$(process_path "$input")
    # Validate path
    if [ -z "$full_path" ]; then
        echo "Error: Invalid path."
        return 1
    fi
    # Check if file exists
    if [ -e "$full_path" ]; then
        # Display file details using stat
        echo "Information for file '$full_path':"
        stat "$full_path"
    else
        echo "File '$full_path' does not exist."
    fi
}

# Function: create_task
# Purpose: Create a new cron job for scheduled tasks.
create_task() {
    # Prompt for command to schedule
    echo -n "Enter the command to schedule (e.g., 'rm -f /path/to/files/*.log'): "
    read -r command
    # Prompt for cron schedule with example
    echo "Enter the schedule (cron format: minute hour day_of_month month day_of_week)"
    echo "Example: '0 2 * * *' for 2:00 AM daily"
    echo -n "Schedule: "
    read -r schedule
    # Validate cron format using regex
    if [[ "$schedule" =~ ^[0-9*]+[[:space:]][0-9*]+[[:space:]][0-9*]+[[:space:]][0-9*]+[[:space:]][0-9*]+$ ]]; then
        # Append new cron job to crontab
        (crontab -l 2>/dev/null; echo "$schedule $command") | crontab -
        if [ $? -eq 0 ]; then
            echo "Task scheduled successfully: '$schedule $command'"
        else
            echo "Error scheduling task."
        fi
    else
        echo "Error: Invalid cron format. Use 'minute hour day_of_month month day_of_week'."
    fi
}

# Function: list_tasks
# Purpose: List all scheduled cron jobs for the current user.
list_tasks() {
    echo "Current scheduled tasks:"
    # Display crontab, or message if empty
    crontab -l 2>/dev/null || echo "No tasks scheduled."
}

# Function: delete_task
# Purpose: Delete a specified cron job by line number.
delete_task() {
    # Show current cron jobs
    list_tasks
    # Prompt for line number to delete
    echo -n "Enter the line number of the task to delete (or 0 to cancel): "
    read -r line_number
    # Check if user cancels
    if [[ "$line_number" == "0" ]]; then
        echo "Cancelled."
        return 0
    fi
    # Validate line number
    if [[ "$line_number" =~ ^[0-9]+$ ]]; then
        # Create temporary file for crontab
        temp_file=$(mktemp)
        crontab -l 2>/dev/null > "$temp_file"
        # Check if line number is valid
        total_lines=$(wc -l < "$temp_file")
        if [ "$line_number" -le "$total_lines" ] && [ "$line_number" -gt 0 ]; then
            # Remove specified line
            sed -i "${line_number}d" "$temp_file"
            # Update crontab
            crontab "$temp_file"
            if [ $? -eq 0 ]; then
                echo "Task deleted successfully."
            else
                echo "Error deleting task."
            fi
        else
            echo "Error: Invalid line number."
        fi
        # Clean up temporary file
        rm -f "$temp_file"
    else
        echo "Error: Invalid input. Enter a number."
    fi
}

# Function: view_time_info
# Purpose: Display current system time, timezone, and NTP status.
view_time_info() {
    echo "Current system time information:"
    # Run timedatectl to show time details
    timedatectl
}

# Function: set_timezone
# Purpose: Set the system timezone.
set_timezone() {
    # Show sample timezones
    echo "Available timezones (examples):"
    ls /usr/share/zoneinfo | head -n 5
    echo "For more, use format like 'Asia/Ho_Chi_Minh' or 'America/New_York'."
    # Prompt for timezone
    echo -n "Enter the timezone (e.g., Asia/Ho_Chi_Minh): "
    read -r timezone
    # Validate timezone
    if [ -f "/usr/share/zoneinfo/$timezone" ]; then
        # Set timezone using timedatectl
        sudo timedatectl set-timezone "$timezone"
        if [ $? -eq 0 ]; then
            echo "Timezone set to '$timezone' successfully."
        else
            echo "Error setting timezone."
        fi
    else
        echo "Error: Invalid timezone."
    fi
}

# Function: toggle_ntp
# Purpose: Enable or disable NTP synchronization for system time.
toggle_ntp() {
    # Show current NTP status
    echo "Current NTP status:"
    timedatectl show --property=NTPSynchronized --value
    # Prompt for enable/disable
    echo -n "Enable NTP synchronization? (y/n): "
    read -r enable_ntp
    if [[ "$enable_ntp" == "y" || "$enable_ntp" == "Y" ]]; then
        # Enable NTP
        sudo timedatectl set-ntp true
        if [ $? -eq 0 ]; then
            echo "NTP synchronization enabled."
        else
            echo "Error enabling NTP."
        fi
    elif [[ "$enable_ntp" == "n" || "$enable_ntp" == "N" ]]; then
        # Disable NTP
        sudo timedatectl set-ntp false
        if [ $? -eq 0 ]; then
            echo "NTP synchronization disabled."
        else
            echo "Error disabling NTP."
        fi
    else
        echo "Invalid choice. No changes made."
    fi
}

# Main loop
# Purpose: Continuously display menu and handle user input.
while true; do
    # Display main menu
    show_menu
    # Read user choice
    read -r choice
    # Validate input format (x.y or 5)
    if [[ "$choice" =~ ^([1-4])\.([1-4])$ ]] || [[ "$choice" == "5" ]]; then
        main_choice="${BASH_REMATCH[1]}"  # Extract main menu choice
        sub_choice="${BASH_REMATCH[2]}"   # Extract sub-menu choice
        # Handle Exit option
        if [ "$choice" == "5" ]; then
            echo "Exiting program."
            exit 0
        # Handle File management
        elif [ "$main_choice" == "1" ]; then
            case $sub_choice in
                1)
                    create_file
                    ;;
                2)
                    delete_file
                    ;;
                3)
                    move_file
                    ;;
                4)
                    check_file_info
                    ;;
            esac
        # Handle Schedule tasks
        elif [ "$main_choice" == "2" ]; then
            case $sub_choice in
                1)
                    create_task
                    ;;
                2)
                    list_tasks
                    ;;
                3)
                    delete_task
                    ;;
                *)
                    echo "Invalid sub-choice for Schedule tasks. Please try again."
                    ;;
            esac
        # Handle System time setup
        elif [ "$main_choice" == "3" ]; then
            case $sub_choice in
                1)
                    view_time_info
                    ;;
                2)
                    set_timezone
                    ;;
                3)
                    toggle_ntp
                    ;;
                *)
                    echo "Invalid sub-choice for System time setup. Please try again."
                    ;;
            esac
        # Handle Package management
        elif [ "$main_choice" == "4" ]; then
            case $sub_choice in
                1)
                    install_package
                    ;;
                2)
                    remove_package
                    ;;
                *)
                    echo "Invalid sub-choice for Package management. Please try again."
                    ;;
            esac
        fi
    else
        # Handle invalid input
        echo "Invalid choice. Please enter a valid option (e.g., 1.1, 2.1, 3.1, 4.1, 5)."
    fi
    # Add blank line for readability
    echo
done