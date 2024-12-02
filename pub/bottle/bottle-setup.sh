#!/bin/bash

# Global variables for parameters
no_new_user=false
new_user=""
new_user_password=""
proceed_apt_tweaks=false
no_apt_tweaks=false
proceed_install_software=false
no_install_software=false
sshd_port=""
no_sshd_port_change=false
no_rmmod=false
proceed_rmmod=false
rmmod_modules=("pcspkr" "module2")
proceed_extra_apt_repos=false
no_extra_apt_repos=false
no_bash_profile=false
proceed_bash_profile=false
proceed=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Parse command-line arguments
for arg in "$@"; do
    case $arg in
    --set-new-user=*)
        new_user="${arg#*=}"
        ;;
    --set-new-user-password=*)
        new_user_password="${arg#*=}"
        ;;
    --no-new-user)
        no_new_user=true
        ;;
    --proceed-apt-tweaks)
        proceed_apt_tweaks=true
        ;;
    --no-apt-tweaks)
        no_apt_tweaks=true
        ;;
    --proceed-install-software)
        proceed_install_software=true
        ;;
    --no-install-software)
        no_install_software=true
        ;;
    --no-sshd-port-change)
        no_sshd_port_change=true
        ;;
    --set-sshd-port=*)
        sshd_port="${arg#*=}"
        ;;
    --no-rmmod)
        no_rmmod=true
        ;;
    --proceed-rmmod)
        proceed_rmmod=true
        ;;
    --proceed-extra-apt-repos)
        proceed_extra_apt_repos=true
        ;;
    --no-extra-apt-repos)
        no_extra_apt_repos=true
        ;;
    --proceed-bash-profile)
        proceed_bash_profile=true
        ;;
    --no-bash-profile)
        no_bash_profile=true
        ;;
    --proceed)
        proceed=true
        ;;
    *)
        echo "Unknown argument: $arg"
        exit 1
        ;;
    esac
done

# Create new user
create_new_user() {
    if [[ $no_new_user == true ]]; then
        echo "Skipping user creation as --no-new-user is set."
        return
    fi

    if [[ -n "$new_user" ]]; then
        create_or_update_user "$new_user" "$new_user_password"
    else
        read -p "Do you want to create a new user for sudo? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            read -p "Enter the new username: " new_user
            create_or_update_user "$new_user" "$new_user_password"
        fi
    fi
}

create_or_update_user() {
    local username="$1"
    local password="$2"

    if id "$username" &>/dev/null; then
        echo "User '$username' already exists."
        read -p "Do you want to change the password for this user? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Changing password for user '$username'."
            passwd "$username"
        else
            echo "Exiting the script."
            exit 1
        fi
    else
        echo "Creating new user '$username'."
        adduser --disabled-password --gecos "" "$username"
        if [[ -n "$password" ]]; then
            echo "$username:$password" | chpasswd
        else
            echo "Setting password for the new user:"
            passwd "$username"
        fi
        usermod -aG sudo "$username"
        echo "$username ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
    fi
}

# Add APT tweaks
add_apt_tweaks() {
    if [[ $no_apt_tweaks == true ]]; then
        echo "Skipping APT tweaks as --no-apt-tweaks is set."
        return
    fi

    if [[ $proceed_apt_tweaks == true ]]; then
        create_apt_tweaks_file
    else
        read -p "Do you want to add APT tweaks? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            create_apt_tweaks_file
        fi
    fi
}

create_apt_tweaks_file() {
    echo "Applying APT tweaks."
    cat <<EOL >/etc/apt/apt.conf.d/00Bottle
APT::Install-Recommends "false";
Acquire::PDiffs "false";
Aptitude::Get-Root-Command "sudo:/usr/bin/sudo";
EOL
}

# Install software
install_software() {
    if [[ $no_install_software == true ]]; then
        echo "Skipping software installation as --no-install-software is set."
        return
    fi

    if [[ $proceed_install_software == true ]]; then
        run_install_software
    else
        read -p "Do you want to install extra packages? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            run_install_software
        fi
    fi
}

run_install_software() {
    echo "Updating package list and installing essential software."
    apt-get update
    apt-get install -y --no-install-recommends openssh-server mc git htop aptitude lsb-release ca-certificates curl build-essential wget
}

# Change SSHD port
change_sshd_port() {
    if [[ $no_sshd_port_change == true ]]; then
        echo "Skipping SSHD port change as --no-sshd-port-change is set."
        return
    fi

    # Check if sshd is installed
    if ! command -v sshd &>/dev/null; then
        echo "SSHD is not installed. Skipping."
        return
    fi

    local current_port=$(grep -iE "^\s*Port\s+" /etc/ssh/sshd_config | awk '{print $2}')
    current_port=${current_port:-22}

    if [[ -n "$sshd_port" ]]; then
        configure_sshd "$sshd_port"
    else
        echo "Current SSHD port: $current_port"
        read -p "Do you want to change the SSHD port? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            read -p "Enter new SSHD port (default: 50055): " sshd_port_input
            sshd_port=${sshd_port_input:-50055}
            configure_sshd "$sshd_port"
        fi
    fi
}

configure_sshd() {
    echo "Configuring SSHD..."
    local port="$1"
    local config_file="/etc/ssh/sshd_config.d/00Bottle.conf"

    mkdir -p /etc/ssh/sshd_config.d
    cat <<EOL >"$config_file"
Port $port
ClientAliveInterval 120
ClientAliveCountMax 10
EOL

    echo "Done. Restarting SSHD service to apply changes."
    systemctl restart sshd
}

# Remove kernel modules
remove_kernel_modules() {
    if [[ $no_rmmod == true ]]; then
        echo "Skipping kernel module removal as --no-rmmod is set."
        return
    fi

    echo "Modules to be removed: ${rmmod_modules[*]}"

    if [[ $proceed_rmmod == true ]]; then
        for module in "${rmmod_modules[@]}"; do
            run_rmmod
        done
    else
        read -p "Do you want to remove these kernel modules? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            run_rmmod
        fi
    fi
}

run_rmmod() {
    for module in "${rmmod_modules[@]}"; do
        if lsmod | grep -q "^$module "; then
            echo "Removing module: $module"
            rmmod "$module" || echo "Failed to remove $module"
        else
            echo "Skipping module $module because it's not loaded."
        fi
    done
}

# Add extra APT repositories
add_extra_apt_repos() {

    if [[ $no_extra_apt_repos == true ]]; then
        echo "Skipping extra APT repositories as --no-extra-apt-repos is set."
        return
    fi

    if [[ $proceed_extra_apt_repos == true ]]; then
        add_php_sury_org
    else
        read -p "Do you want to add extra APT repositories? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            add_php_sury_org
        #else
        #    echo "Skipping addition of extra APT repositories."
        fi
    fi
}

# Function to add PHP from sury.org
add_php_sury_org() {
    local DDISTRO="bookworm"
    #local DDISTRO=$(lsb_release -cs)
    echo "Adding sury.org repository for PHP."

    apt-get update
    curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    dpkg -i /tmp/debsuryorg-archive-keyring.deb
    sh -c "echo 'deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $DDISTRO main' > /etc/apt/sources.list.d/php.list"
    apt-get update

    echo "sury.org repository added successfully."
}

# Add bottle-bash.profile
add_bash_profile() {
    if [[ $no_bash_profile == true ]]; then
        echo "Skipping adding bottle-bash.profile as --no-bash-profile is set."
        return
    fi

    if [[ $proceed_bash_profile == true ]]; then
        run_add_bash_profile
    else
        read -p "Do you want to add bottle-bash.profile with handy bash aliases? [Y/n]: " response
        response=${response:-Y}
        if [[ "$response" =~ ^[Yy]$ ]]; then
            run_add_bash_profile
        fi
    fi
}

run_add_bash_profile() {
    echo "Adding bottle-bash.profile"
    #local file_url="http://192.168.76.101:3000/bottle-bash.profile"
    local file_url="https://raw.githubusercontent.com/pwlin/pwlin.github.io/refs/heads/master/pub/bottle/bottle-bash.profile"

    if [ -f "$SCRIPT_DIR/bottle-bash.profile" ]; then
        cp "$SCRIPT_DIR/bottle-bash.profile" "$HOME/bottle-bash.profile"
    else
        wget -O "$HOME/bottle-bash.profile" $file_url
    fi

    # add this in the .bashrc:
    #if [ -f ~/bottle-bash.profile ]; then
    #. ~/bottle-bash.profile
    #fi

    local line="if [ -f \$HOME/bottle-bash.profile ]; then\n . \$HOME/bottle-bash.profile\nfi"
    local bashrc_file="$HOME/.bashrc"

    # Check if the line already exists in .bashrc
    if ! grep -qF "if [ -f \$HOME/bottle-bash.profile ]; then" "$bashrc_file"; then
        # Append the line to .bashrc
        echo -e "$line" >>"$bashrc_file"
        echo "Added to $bashrc_file"
    else
        echo "The specified lines already exist in $bashrc_file"
    fi

}

# Main function
main() {
    if ! $proceed; then
        read -p "This script will make significant changes to your system. Do you want to proceed? [Y/n]: " response
        response=${response:-Y}
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Exiting script."
            exit 0
        fi
    fi

    echo "Starting script execution."
    create_new_user
    add_apt_tweaks
    install_software
    change_sshd_port
    remove_kernel_modules
    add_extra_apt_repos
    add_bash_profile
    echo "Script execution completed."
}

main
