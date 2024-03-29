#!/bin/bash
# Anthony Manenti - NOS125-150 SP23
# Interactive shell script combining all scripting and config tasks for NOS125.

# This script was put together with a lot of head scratching, trial and error, and googling. THANK YOU Linux forums, StackOverflow, Github, classmates and faculty!
# Please feel free to use this script as a reference, to build upon it, and improve it.

# TODOS:
# 1) Generally my input validation on the case statements in the script feels a bit clunky. (using booleans and while loops) There is likely a more efficent means of doing this.
# 2) It would be really cool if I could figure out how to launch a program like nmtuiand return the user back to my script once they are done.
# 3) A readme would be nice.
# 4) Functionality for creating additional users, adding them as sudoers. Setting their passwords.
# 5) IP address validation. (WIP)
# 6) Make an array of Linux / Dad jokes and add a random joke picker function to the main menu where a random joke is picked and display.

# GREMLINS:
# Occasionally auto disk configuration can be a little screwy. (but it does work) Removing files from /data first usually allows the process to go through. I'm not sure what's happening here yet.

# COLOR HELPERS
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# VALIDATION HELPERS
is_num='^[0-9]+$'
is_ranged_num='^[0-9]$|^10$'

# these validators are somewhat flawed. They don't take into account valid IP ranges. But atleast it's something.
# IP Validation Regex (https://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp)
is_cidr='^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$'
is_ip='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'

# OTHER HELPERS
version="1.0.0"
heading="Tux ToolBox v $version"

# MARK: CALLER

# Gives us the multi option prompt and allows us to call functions as we need them.
# This kind of pattern is useful, because it allows us to block everything away and work on one piece at a time.
# We don't have to worry about massive entangled blocks. It's a caller basically.
call_menu() {
    clear
    echo -e "${YELLOW}$heading${NC}"

    echo -e "\n1) Set Hostname\n2) Create Files and Folders\n3) Delete Files and Folders\n4) Configure Networking\n5) Install Git\n6) Configure Storage\n\nQ) Quit\n"
    read -p "Welcome! What would you like to do? " input
    case $input in
    1)
        set_hostname
        ;;
    2)
        prompt_num_files
        ;;
    3)
        delete_all_files
        ;;
    4)
        configure_networking
        ;;
    5)
        install_git
        ;;
    6)
        prompt_config_storage
        ;;
    [qQ])
        exit
        ;;
    *)
        echo "invalid option"
        sleep 2
        call_menu
        ;;
    esac
}

# MARK: HOSTNAMES

# Allows user to set hostname
set_hostname() {
    clear
    local inval_guard=true
    echo -e "\n${YELLOW}$heading : HOSTNAME CONFIG${NC}\n"
    read -p "Please enter your hostname : " hostname
    while $inval_guard; do
        echo -e "\nYour new hostname will be : $hostname\n"
        read -p "Please confirm this change. (y/n) (q: quit without saving) " ynq
        case $ynq in
        [yY])
            inval_guard=false
            echo "Changing hostname now" hostnamectl set-hostname $hostname
            call_menu
            ;;
        [nN])
            inval_guard=false
            set_hostname
            ;;
        [qQ])
            inval_guard=false
            call_menu
            ;;
        *)
            echo invalid response
            sleep 2
            ;;
        esac
    done
}

# MARK: FILE AND FOLDER CREATION

# Kicks off file and default folder creation chain, sends user input to validate.
prompt_num_files() {
    clear
    echo -e "\n${YELLOW}$heading : FILES AND FOLDERS${NC}\n"
    echo "How many files would you like to create? [must be an integer]. "
    read N
    if ! [[ $N =~ $is_num ]]; then
        echo error: Not a number. Try again.
        sleep 2
        prompt_num_files
    else
        prompt_file_size
    fi
}

# Ask for file size in MB, send to validate.
prompt_file_size() {
    clear
    echo -e "\n${YELLOW}$heading : FILES AND FOLDERS${NC}\n"
    echo "How many MBs would you like the files to be? [must be an integer]. "
    read S
    if ! [[ $S =~ $is_num ]]; then
        echo error: Not a number. Try again.
        sleep 2
        prompt_file_size
    else
        clear
        prompt_default_folders
    fi
}

# Ask user if they want the default folders.
prompt_default_folders() {
    clear
    echo -e "\n${YELLOW}$heading : FILES AND FOLDERS${NC}\n"
    read -p "Would you like to create a set of default folders in data/groups? (y/n) " yn
    case $yn in
    [yY])
        paths=("sales" "marketing" "operations" "finance" "human_resources")
        for path in "${paths[@]}"; do
            sudo mkdir -p /data/groups/$path
        done
        prompt_num_folders
        ;;
    [nN])
        prompt_num_folders
        ;;
    *)
        echo invalid response
        prompt_default_folders
        ;;
    esac
}

prompt_num_folders() {
    existing_scripted_dirs=()
    new_scripted_dirs=()

    clear
    echo -e "\n${YELLOW}$heading : FILES AND FOLDERS${NC}\n"
    # Populate existing_scripted_dirs array
    for i in {1..10}; do
        if [ -d "/data/public/folder$i" ]; then
            existing_scripted_dirs+=("folder$i")
        fi
    done

    # If folder[1..10] already exists, there's no reason to prompt the user to recreate them.
    if [ "${#existing_scripted_dirs[@]}" -eq 10 ]; then
        echo -e "${YELLOW}All possible scripted folders already exist!${NC}"
        sleep 2
        test_existing_files
    fi

    echo -e "This script will create a collection of folders for you (if they do not already exist), labled folder[1..X] (max: 10) in data/public.\n"
    read -p "How many folders do you want? " nF

    if ! [[ $nF =~ $is_ranged_num ]]; then
        echo error: "Invalid response. Try again."
        sleep 2
        prompt_num_folders
    else
        # If this was any more complicated, this approach would be too brittle.
        # We're taking in the user input for number of folders they want, appending it to a search string, pushing it to an array to list to the user and doing nothing if we find it.
        for i in $(seq 1 $nF); do
            if ! [ -d "/data/public/folder$i" ]; then
                sudo mkdir -p "/data/public/folder$i"
                new_scripted_dirs+=("folder$i")
            fi
        done
        test_existing_files
    fi
}

# Test to see if there are already files present in target directories. Ask for confirmation before blowing them away.
test_existing_files() {
    all_dirs=($(ls -d /data/public/*/ | xargs -n1 basename))
    clear
    echo -e "\n${YELLOW}$heading : FILES AND FOLDERS${NC}\n"

    if [ "${#new_scripted_dirs[@]}" -gt 0 ]; then
        echo -e "New directories:\n"
        for dir in "${new_scripted_dirs[@]}"; do
            echo -e "${GREEN}$dir${NC}"
        done
    fi

    if [ "${#existing_scripted_dirs[@]}" -gt 0 ]; then
        echo -e "\nExisting directories:\n"
        for dir in "${existing_scripted_dirs[@]}"; do
            echo -e "${YELLOW}$dir${NC}"
        done
    fi

    echo -e "\nFolders currently present in /data/public:\n"
    for dir in "${all_dirs[@]}"; do
        printf "${BLUE}%-10s${NC}" "$dir"
    done
    echo -e "\n"

    local inval_guard=true
    read -p "What directory would you like to write the files to? (name must appear in list) " target
    if grep -q "$target" <<<"${all_dirs[*]}"; then
        if [[ -z $(ls -A "/data/public/$target") ]]; then
            create_files
        else
            while $inval_guard; do
                echo -e "${RED}\nFiles are already present in the target directory. If you continue any duplicated files will be overwritten.${NC}\n"
                read -p "Are you sure you wish to continue? (y: overwrite duplicates, q: quit, d: delete directory contents and write fresh) " yqd
                case $yqd in
                [yY])
                    inval_guard=false
                    create_files
                    ;;
                [qQ])
                    inval_guard=false
                    call_menu
                    ;;
                [dD])
                    inval_guard=false
                    sudo rm -rf /data/public/$target/*
                    create_files
                    ;;
                *)
                    echo "Invalid response."
                    sleep 2
                    test_existing_files
                    ;;
                esac
            done
        fi
    else
        echo "Please pick a folder that is present in /data/public"
        sleep 2
        test_existing_files
    fi
}

# Create the files.
create_files() {
    for i in $(seq 1 $N); do
        sudo dd if=/dev/zero of=/data/public/$target/some_file$i bs=$S count=1
    done
    echo "Files created! returning to main menu."
    sleep 2
    call_menu
}

# MARK : FILE DELETION

# Simple and dumb delete. Delete all the things. Godspeed.
delete_all_files() {
    clear
    echo -e "\n${YELLOW}$heading : FILE DELETION${NC}\n"
    echo -e "${RED}WARNING: This will remove all files and folder from /data/public and /data/groups.${NC}\n"
    read -p "Are you sure you want to do this? (y/n) " yn
    case $yn in
    [Yy])
        sudo rm -rf /data/public
        sudo rm -rf /data/groups
        call_menu
        ;;
    [Nn])
        call_menu
        ;;
    *)
        echo "invalid option"
        sleep 2
        delete_all_files
        ;;
    esac
}

# MARK: NETWORKING

# allows user to use our wizard for network config through nmcli command formatting, or opt to use nmtui
configure_networking() {
    clear
    echo -e "\n${YELLOW}$heading : NETWORK CONFIG${NC}"
    echo -e "\n1) I want to use this script to configure network settings \n2) I want to use nmtui to configure network settings \n\nQ) Quit \n"
    read -p "How can I help you today? " input
    case $input in
    1)
        input_ip_address
        ;;
    2)
        sudo nmtui
        ;;
    [qQ])
        call_menu
        ;;
    *)
        echo "invalid option"
        sleep 2
        configure_networking
        ;;
    esac
}

# prompt for and validate ip address, send to gateway address function if valid. else prompt again.
input_ip_address() {
    clear
    echo -e "\n${YELLOW}$heading : NETWORK CONFIG${NC}\n"
    read -p "Enter an IP address with CIDR notation (e.g., 192.168.1.0/24): " ip
    if [[ $ip =~ $is_cidr ]]; then
        input_gateway_address "$ip"
    else
        echo "Invalid IP address. Try again"
        sleep 2
        input_ip_address
    fi
}

# prompt for and validate gateway address, send to optional dns function if valid, else prompt again.
input_gateway_address() {
    clear
    echo -e "\n${YELLOW}$heading : NETWORK CONFIG${NC}\n"
    read -p "Enter your gateway IP address: " gw
    if [[ $gw =~ $is_ip ]]; then
        input_dns "$1" "$gw"
    else
        echo "Invalid IP address."
        sleep 2
        input_gateway_address
    fi
}

# prompt for optional dns address, if valid, send to confirm, if user opts out, send to confirm with nil dns variable.
input_dns() {
    clear
    echo -e "\n${YELLOW}$heading : NETWORK CONFIG${NC}\n"
    local inval_guard=true
    while $inval_guard; do
        read -p "Do you want to override the system default DNS settings? (y/n) " yn
        case $yn in
        [yY])
            # Not super DRY here. we're repeating logic we already have, but this is easier than redirecting for now.
            read -p "Enter your custom DNS address " dns
            if [[ $dns =~ $is_ip ]]; then
                inval_guard=false
                confirm_net_config "$1" "$2" "$dns"
            else
                echo "Invalid IP address."
                sleep 2
                clear
            fi
            ;;
        [nN])
            dns=""
            inval_guard=false
            confirm_net_config "$1" "$2" "$dns"
            ;;
        *)
            echo "invalid response"
            sleep 2
            ;;
        esac
    done
}

# Creates a prompt which allows users to confirm their network config before applying.
confirm_net_config() {
    clear
    echo -e "\n${YELLOW}$heading : NETWORK CONFIG${NC}"
    # This is running the IP link command and then using AWK to find the first line that starts with a number, followed by a colon and then a space and then the letter e, which is the interface we want to change.
    iface=$(ip link | awk -F': ' '/^[0-9]+: e/{print $2; exit}')

    # print config back to user for confirmation.
    echo -e "\n${GREEN} IP : $1\n Gateway : $2\n DNS : $3\n Interface : $iface${NC}\n "
    read -p "Please confirm you configuration before applying (y: confirm, n: restart config, or q: quit to main menu) " ynq
    case $ynq in
    [yY])
        # Check if third param (DNS) is null, format nmcli accordingly and run.
        if [ -z "$3" ]; then
            sudo nmcli connection add con-name static type ethernet ifname "$iface" ipv4.addresses "$1" ipv4.gateway "$2" ipv4.method manual
        else
            sudo nmcli connection add con-name static type ethernet ifname "$iface" ipv4.addresses "$1" ipv4.gateway "$2" ipv4.dns "$3" ipv4.method manual
        fi
        prompt_interface_up
        ;;
    [nN])
        input_ip_address
        ;;
    [qQ])
        call_menu
        ;;
    *)
        echo "invalid response"
        sleep 2
        confirm_net_config
        ;;
    esac
}

# Ask user if they want to bring the modified interface profile up. Warn that they may be disconnected.
prompt_interface_up() {
    echo
    echo -e "\n${RED}WARNING: Bringing up your connection now will disconnect you if you are connected via SSH. If you choose not to do this now, you will be taken back to the main menu and the configuration will be appplied on reboot.${NC}\n"
    read -p "Do you want to bring up your newly configured connection now? (y/n) " yn
    case $yn in
    [yY])
        sudo nmcli connection up static
        call_menu
        ;;
    [nN])
        call_menu
        ;;
    *)
        echo "invalid response"
        sleep 2
        prompt_interface_up
        ;;
    esac
}

# MARK : GIT CONFIGURATION

# It do what it says it do.
install_git() {
    local inval_guard=true
    clear
    echo -e "\n${YELLOW}$heading : GIT CONFIG${NC}\n"
    # Check if git installed. Silence output - if it aint. install it.
    if ! command -v git &>/dev/null; then
        echo "Git is not installed. Installing Git..."
        sudo dnf install -y git
    else
        echo "Git is already installed"
    fi

    while $inval_guard; do
        read -p "Would you like to create an SSH key and SSH config file now? (y/n) " yn
        case $yn in
        [yY])
            inval_guard=false
            create_ssh_config
            ;;
        [nN])
            inval_guard=false
            call_menu
            ;;
        *)
            echo "invalid response"
            sleep 2
            ;;
        esac
    done
}

# Create SSH config  for user. Lovely lil nested conditionals.
create_ssh_config() {
    clear
    echo -e "\n${YELLOW}$heading : GIT CONFIG${NC}\n"
    read -p "Please name your ssh key (no spaces allowed) " name

    # Check if it has spaces in it. We don't like spaces.
    if [[ $name == *" "* || -z $name ]]; then
        echo "Invalid name, please try again ..."
        sleep 2
        create_ssh_config
    else
        # Make sure we aint trying to overwrite anything. Prompt again if we are.
        if [ -f ~/.ssh/$name ]; then
            echo "Careful! A key of this name already exists, please enter another name."
            sleep 2
            create_ssh_config
        else
            echo "Creating SSH key..."
            ssh-keygen -t rsa -N "" -f ~/.ssh/$name
            # If they already have a config entry for github. Don't make it complicated. Tell them to look at the file.
            if grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
                echo "You already have a config file entry for github. Please review your config file."
            else
                echo -e "\nHost github.com" >>~/.ssh/config
                echo "  User git" >>~/.ssh/config
                echo "  IdentityFile ~/.ssh/$name" >>~/.ssh/config
            fi
        fi
        echo -e "\nAutomatic configuration of Git complete"
        sleep 3
        call_menu
    fi
}

# MARK : STORAGE CONFIGURATION

# Multi choice menu for different storage configuration options
prompt_config_storage() {
    clear
    echo -e "\n${YELLOW}$heading : STORAGE CONFIG${NC}\n"
    printf "${GREEN}"
    lsblk
    printf "${NC}"
    echo -e "\nOPTIONS :\n\n1) I want to use this script to automatically configure /dev/sdc\n2) I want to use fdisk to manually configure /dev/sdc\n3) unmount /dev/sdc1\n4) unmount and zero /dev/sdc\n\nQ) Quit \n"
    read -p "How can I help you today? " input
    case $input in
    1)
        check_storage
        ;;
    2)
        sudo fdisk /dev/sdc
        ;;
    3)
        sudo umount /dev/sdc1
        sleep 2
        call_menu
        ;;
    4)
        confirm_destroy
        ;;
    [qQ])
        call_menu
        ;;
    *)
        echo "invalid option"
        sleep 2
        prompt_config_storage
        ;;
    esac
}

# Check to see if /dev/sdc even exists. Check to see if a folder already exists at /data - if it does it might have data.
# If /dev/sdc exists, advance prompt. If not bounce user out and tell them to figure themselves out.
check_storage() {
    clear
    echo -e "\n${YELLOW}$heading : STORAGE CONFIG${NC}\n"
    if lsblk -f /dev/sdc >/dev/null 2>&1; then
        if [ -d /data ]; then
            echo -e "${RED}WARNING: You already have a folder located at /data. This script will mount a drive at that location. If there is data present in this folder it will become hidden until the drive is unmounted.${NC}\n"
            read -p "Are you sure you wish to continue? (y: continue, n: exit) " input
            case $input in
            [yY])
                auto_config_storage
                ;;
            [nN])
                call_menu
                ;;
            *)
                echo "invalid input"
                sleep 2
                check_storage
                ;;
            esac
        else
            auto_config_storage
        fi
    else
        echo "Please check your storage configuration /dev/sdc is not a attached storage device"
        sleep 2
        call_menu
    fi
}

# Automated flow for disk configuration in spec with NOS-125 requirements. Create /etc/fstab entry for automatic mounting.
auto_config_storage() {
    clear
    echo -e "\n${YELLOW}$heading : STORAGE CONFIG${NC}\n"
    # if /data doesn't exist make it.
    if [ ! -d /data ]; then
        sudo mkdir /data
    fi

    # Guard clause. If we already have our partition set up. do nothing.
    if lsblk -f /dev/sdc1 >/dev/null 2>&1; then
        echo -e "${RED}/dev/sdc1 has already been configured or already contains a file system. Automatic configuration is risky.${NC}"
        echo "The script will return you to the storage configuration menu..."
        sleep 3
        prompt_config_storage
    fi

    # CREDIT : S. White (GitHub:whites3507) - https://github.com/NOS-DTCC-SW/NOS125-SP23/blob/main/scripted_commands
    echo -e "n\np\n1\n\n\nw" | sudo fdisk /dev/sdc
    sudo mkfs.ext4 /dev/sdc1
    sudo chown $USER:$USER -R /data
    sudo mount /dev/sdc1 /data

    # Check to see if we already have an /etc/fstab entry for /dev/sdc.
    # It's possible the user may have executed the script before. We don't need to litter the file up.
    if ! grep -q /dev/sdc1 /etc/fstab; then
        # Learned something new here... you can't echo into a protected system file without tee apparently... https://stackoverflow.com/questions/84882/sudo-echo-something-etc-privilegedfile-doesnt-work
        echo "/dev/sdc1    /dev/sdc1    auto    defaults    0    0" | sudo tee -a /etc/fstab >/dev/null
        echo "Added entry for /dev/sdc1 in /etc/fstab"
    fi
    sleep 3
    call_menu
}

# Confirmation dialog and commands for zeroing disks.
confirm_destroy() {
    clear
    echo -e "\n${YELLOW}$heading : STORAGE CONFIG${NC}\n"
    echo -e "${RED}Woah! Let's not be too hasty... This is going to delete everything on /dev/sdc!!!${NC}\n"
    read -p "Are you sure about this? (y/n) " yn
    case $yn in
    [yY])
        echo -e "\n As you wish... Nuking everything. Remind me not to get on your bad side.\n"
        sudo umount /dev/sdc >/dev/null 2>&1
        sudo dd if=/dev/zero of=/dev/sdc status=progress
        sleep 2
        prompt_config_storage
        ;;
    [nN])
        prompt_config_storage
        ;;
    *)
        echo invalid response
        sleep 2
        confirm_destroy
        ;;
    esac
}

# Basically shell script loads from top to bottom... so the interpreter runs down the file, gets all my function definitions, and at the last moment we call the caller function to kick this thing off.
call_menu
