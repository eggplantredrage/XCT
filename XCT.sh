#!/bin/bash

# Function to detect distribution and package manager
function get_distro {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

# Function for the dialog menu
function show_menu {
    # Menu height remains 7
    dialog --clear --menu "XCT XIX Command Tool" 15 50 7 \
    1 "Update Grub" \
    2 "Update Repositories" \
    3 "Repair Broken Packages" \
    4 "Remove Package" \
    5 "Search Packages" \
    6 "Install Package" \
    7 "See System Info" \
    8 "About Screen" \
    0 "Exit" 2>/tmp/menu_choice.txt
}

# Detect the distribution
distro=$(get_distro)

# Main code loop
while true; do
    show_menu
    
    # Read the user's selection from the temporary file
    choice=$(cat /tmp/menu_choice.txt)
    
    case "$choice" in
        1) 
            clear
            if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                sudo update-grub
            elif [ "$distro" == "fedora" ]; then
                sudo grub2-mkconfig -o /boot/grub2/grub.cfg
            elif [ "$distro" == "arch" ]; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            elif [ "$distro" == "gentoo" ]; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            fi
            dialog --msgbox "Grub update completed." 10 50
            ;;
        2) 
            clear
            if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                sudo apt-get -y update
            elif [ "$distro" == "fedora" ]; then
                sudo dnf -y update
            elif [ "$distro" == "arch" ]; then
                sudo pacman -Syu
            elif [ "$distro" == "gentoo" ]; then
                sudo emerge --sync
            fi
            dialog --msgbox "Repository update completed." 10 50
            ;;
        3) 
            clear
            if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                sudo apt --fix-missing update
                sudo apt-get clean
            elif [ "$distro" == "fedora" ]; then
                sudo dnf check --fix-missing
                sudo dnf clean all
            elif [ "$distro" == "arch" ]; then
                sudo pacman -Syu --needed
                sudo pacman -Scc
            elif [ "$distro" == "gentoo" ]; then
                sudo emerge --fix-missing
                sudo eclean-dist
            fi
            dialog --msgbox "Broken packages repaired." 10 50
            ;;
        # Option 4 is now for removing packages
        4) 
            clear
            PACKAGE_TO_REMOVE=$(dialog --inputbox "Enter package name to remove:" 10 50 2>&1 >/dev/tty)
            
            if [ -z "$PACKAGE_TO_REMOVE" ]; then
                dialog --msgbox "Package removal cancelled or no package name entered." 10 50
            else
                dialog --infobox "Attempting to remove '$PACKAGE_TO_REMOVE'..." 5 50
                sleep 2 # Give time for the infobox to be seen
                
                if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                    sudo apt-get remove -y "$PACKAGE_TO_REMOVE"
                elif [ "$distro" == "fedora" ]; then
                    sudo dnf remove -y "$PACKAGE_TO_REMOVE"
                elif [ "$distro" == "arch" ]; then
                    sudo pacman -Rns --noconfirm "$PACKAGE_TO_REMOVE" # -Rns removes package and its unneeded dependencies
                elif [ "$distro" == "gentoo" ]; then
                    sudo emerge --depclean "$PACKAGE_TO_REMOVE" # --depclean removes unneeded dependencies
                else
                    dialog --msgbox "Unsupported distribution for package removal." 10 50
                    continue # Go back to main loop
                fi

                if [ $? -eq 0 ]; then
                    dialog --msgbox "Package '$PACKAGE_TO_REMOVE' removed successfully." 10 50
                else
                    dialog --msgbox "Failed to remove package '$PACKAGE_TO_REMOVE'. Check the package name." 10 50
                fi
            fi
            ;;
        # Option 5 is now a package search function
        5) 
            clear
            SEARCH_TERM=$(dialog --inputbox "Enter package name or keyword to search:" 10 60 2>&1 >/dev/tty)
            
            if [ -z "$SEARCH_TERM" ]; then
                dialog --msgbox "Package search cancelled or no search term entered." 10 50
            else
                TEMP_SEARCH_RESULTS_FILE=$(mktemp)
                echo "--- Search Results for '$SEARCH_TERM' ---" > "$TEMP_SEARCH_RESULTS_FILE"
                echo "" >> "$TEMP_SEARCH_RESULTS_FILE"

                if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                    apt search "$SEARCH_TERM" >> "$TEMP_SEARCH_RESULTS_FILE" 2>&1
                elif [ "$distro" == "fedora" ]; then
                    dnf search "$SEARCH_TERM" >> "$TEMP_SEARCH_RESULTS_FILE" 2>&1
                elif [ "$distro" == "arch" ]; then
                    pacman -Ss "$SEARCH_TERM" >> "$TEMP_SEARCH_RESULTS_FILE" 2>&1
                elif [ "$distro" == "gentoo" ]; then
                    equery search "$SEARCH_TERM" >> "$TEMP_SEARCH_RESULTS_FILE" 2>&1
                else
                    echo "Unsupported distribution for package search." >> "$TEMP_SEARCH_RESULTS_FILE"
                fi

                # Check if the search yielded any results
                # Exclude the header and empty line from the check
                if [ "$(wc -l < "$TEMP_SEARCH_RESULTS_FILE")" -le 2 ]; then
                    echo "No packages found matching '$SEARCH_TERM'." >> "$TEMP_SEARCH_RESULTS_FILE"
                fi

                dialog --textbox "$TEMP_SEARCH_RESULTS_FILE" 20 70
                rm -f "$TEMP_SEARCH_RESULTS_FILE"
            fi
            ;;
        # Option 6: Package Installer
        6)
            clear
            PACKAGE_NAME=$(dialog --inputbox "Enter package name to install:" 10 50 2>&1 >/dev/tty)
            
            # Check if the user entered a package name or cancelled
            if [ -z "$PACKAGE_NAME" ]; then
                dialog --msgbox "Package installation cancelled or no package name entered." 10 50
            else
                dialog --infobox "Attempting to install '$PACKAGE_NAME'..." 5 50
                sleep 2 # Give time for the infobox to be seen
                
                if [ "$distro" == "ubuntu" ] || [ "$distro" == "debian" ]; then
                    sudo apt-get install -y "$PACKAGE_NAME"
                elif [ "$distro" == "fedora" ]; then
                    sudo dnf install -y "$PACKAGE_NAME"
                elif [ "$distro" == "arch" ]; then
                    sudo pacman -S --noconfirm "$PACKAGE_NAME"
                elif [ "$distro" == "gentoo" ]; then
                    sudo emerge --ask "$PACKAGE_NAME"
                else
                    dialog --msgbox "Unsupported distribution for package installation." 10 50
                    continue # Go back to main loop
                fi

                if [ $? -eq 0 ]; then
                    dialog --msgbox "Package '$PACKAGE_NAME' installed successfully." 10 50
                else
                    dialog --msgbox "Failed to install package '$PACKAGE_NAME'. Check the package name or your internet connection." 10 50
                fi
            fi
            ;;
        # Option 7 displays system information
        7) 
            clear
            # Create a temporary file to store system information
            TEMP_INFO_FILE=$(mktemp)
            
            # Populate the temporary file with system details
            echo "--- System Information ---" > "$TEMP_INFO_FILE"
            echo "" >> "$TEMP_INFO_FILE"
            echo "Hostname: $(hostname)" >> "$TEMP_INFO_FILE"
            
            # Get Operating System details from /etc/os-release (common on most Linux distros)
            if [ -f /etc/os-release ]; then
                . /etc/os-release # Source the file to get variables like PRETTY_NAME
                echo "Operating System: $PRETTY_NAME" >> "$TEMP_INFO_FILE"
            else
                echo "Operating System: Unknown or /etc/os-release not found" >> "$TEMP_INFO_FILE"
            fi
            
            echo "Kernel: $(uname -r)" >> "$TEMP_INFO_FILE"
            echo "Architecture: $(uname -m)" >> "$TEMP_INFO_FILE"
            
            echo "" >> "$TEMP_INFO_FILE"
            echo "--- Memory Usage ---" >> "$TEMP_INFO_FILE"
            free -h >> "$TEMP_INFO_FILE" # Append memory usage
            
            echo "" >> "$TEMP_INFO_FILE"
            echo "--- Disk Usage (Root Partition) ---" >> "$TEMP_INFO_FILE"
            df -h / >> "$TEMP_INFO_FILE" # Append disk usage for root

            # Display the captured information using dialog --textbox
            # This will show a scrollable textbox with the content of the temporary file
            dialog --textbox "$TEMP_INFO_FILE" 20 70
            
            # Clean up the temporary file after displaying
            rm -f "$TEMP_INFO_FILE"
            ;;
        # Option 8: About Screen
        8) 
            dialog --msgbox "XCT 2021-2025 XIX Technology By Eggplant48 v0.8 This Software Is License Under GPL 3 " 10 50
            ;;
        0) 
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Invalid option. Please select a valid option." 10 50
            ;;
    esac
done
