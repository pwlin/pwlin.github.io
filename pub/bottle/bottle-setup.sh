#!/bin/bash

# Global variables for parameters
new_user=""
new_user_password=""
ssh_port="50055"
no_new_user=false
no_ssh_port_change=false
no_apt_tweaks=false
no_install_software=false
no_rmmod=false
proceed=false
rmmod_modules=( "pcspkr" "module2" ) # Example modules

# Parse command-line arguments
for arg in "$@"; do
  case $arg in
    --set-new-user=*)
      new_user="${arg#*=}"
      ;;
    --set-new-user-password=*)
      new_user_password="${arg#*=}"
      ;;
    --set-ssh-port=*)
      ssh_port="${arg#*=}"
      ;;
    --no-new-user)
      no_new_user=true
      ;;
    --no-ssh-port-change)
      no_ssh_port_change=true
      ;;
    --no-apt-tweaks)
      no_apt_tweaks=true
      ;;
    --no-install-software)
      no_install_software=true
      ;;
    --no-rmmod)
      no_rmmod=true
      ;;
    --set-rmmod)
      proceed_rmmod=true
      ;;
    --add-extra-apt-repos)
      add_extra_apt_repos=true
      ;;
    --no-extra-apt-repos)
      no_extra_apt_repos=true
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

# Task 1: Create a new user for sudo
create_new_user() {
  if $no_new_user; then 
    echo "Skipping user creation as --no-new-user is set." 
    return; 
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
    echo "$username ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  fi
}

# Task 2: Change SSH default port
change_ssh_port() {
  if $no_ssh_port_change; then 
    echo "Skipping SSH port change as --no-ssh-port-change is set." 
    return; 
  fi

  local current_port=$(grep -iE "^\s*Port\s+" /etc/ssh/sshd_config | awk '{print $2}')
  current_port=${current_port:-22} # Default port is 22 if not explicitly set

  if [[ -n "$ssh_port" ]]; then
    configure_ssh "$ssh_port"
  else
    echo "Current SSH port: $current_port"
    read -p "Do you want to change the SSH port? [Y/n]: " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy]$ ]]; then
      read -p "Enter new SSH port (default: 65500): " ssh_port_input
      ssh_port=${ssh_port_input:-65500}
      configure_ssh "$ssh_port"
    fi
  fi
}

configure_ssh() {
  local port="$1"
  local config_file="/etc/ssh/sshd_config.d/00Bottle.conf"

  mkdir -p /etc/ssh/sshd_config.d
  cat <<EOL > "$config_file"
Port $port
ClientAliveInterval 120
ClientAliveCountMax 10
EOL

  echo "Restarting SSH service to apply changes."
  systemctl restart sshd
}

# Task 3: Add APT tweaks
add_apt_tweaks() {
  if $no_apt_tweaks; then 
    echo "Skipping APT tweaks as --no-apt-tweaks is set." 
    return; 
  fi

  echo "Applying APT tweaks."
  cat <<EOL > /etc/apt/apt.conf.d/00Bottle
APT::Install-Recommends "false";
Acquire::PDiffs "false";
Aptitude::Get-Root-Command "sudo:/usr/bin/sudo";
EOL
}

# Task 4: Install software
install_software() {
  if $no_install_software; then 
    echo "Skipping software installation as --no-install-software is set." 
    return; 
  fi

  echo "Updating package list and installing essential software."
  apt-get update
  apt-get install -y --no-install-recommends mc git htop aptitude lsb-release ca-certificates curl 
}

# Task 5: Remove kernel modules
remove_kernel_modules() {
  if $no_rmmod; then
    echo "Skipping kernel module removal as --no-rmmod is set."
    return
  fi

  echo "Modules to be removed: ${rmmod_modules[*]}"

  if [[ $proceed_rmmod == true ]]; then
    for module in "${rmmod_modules[@]}"; do
      if lsmod | grep -q "^$module "; then
        echo "Removing module: $module"
        rmmod "$module" || echo "Failed to remove $module"
      else
        echo "Skipping module $module because it's not loaded."
      fi
    done
  else
    read -p "Do you want to remove these kernel modules? [Y/n]: " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy]$ ]]; then
      for module in "${rmmod_modules[@]}"; do
        if lsmod | grep -q "^$module "; then
          echo "Removing module: $module"
          rmmod "$module" || echo "Failed to remove $module"
        else
          echo "Skipping module $module because it's not loaded."
        fi
      done
    fi
  fi
}

# Task 6: Add extra APT repositories
add_extra_apt_repos() {
  #if $no_extra_apt_repos; then
  #  echo "Skipping extra APT repositories as --no-extra-apt-repos is set."
  #  return
  #fi

  if [[ $add_extra_apt_repos == true ]]; then
    add_php_sury_org
  else
    read -p "Do you want to add extra APT repositories? [Y/n]: " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy]$ ]]; then
      add_php_sury_org
    else
      echo "Skipping addition of extra APT repositories."
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
  change_ssh_port
  add_apt_tweaks
  install_software
  remove_kernel_modules
  add_extra_apt_repos
  echo "Script execution completed."
}

main
