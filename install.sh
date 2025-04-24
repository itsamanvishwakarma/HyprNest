#!/bin/bash

HYPRNEST_DIR="$(pwd)"

# Define text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# check if any command was successful or not
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${BOLD}$1${RESET}"
    else
        echo -e "${RED}${BOLD}Error:${RESET} $2"
        exit 1
    fi
}

# check if pacman is installed
check_pacman() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}${BOLD}Error:${RESET} pacman is not installed on this system."
        echo -e "Please install pacman and try again."
        exit 1
    else
        echo -e "${GREEN}${BOLD}Pacman is installed.${RESET} Proceeding further..."
    fi
}

# Function to check if yay or paru is installed
check_aur_helper() {
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}${BOLD}An AUR helper yay is already installed.${RESET}"
    elif command -v paru &> /dev/null; then
        echo -e "${GREEN}${BOLD}An AUR helper paru is already installed.${RESET}"
    else
        return 1
    fi
}

# Function to check and enable NetworkManager
check_network_manager() {
    if ! systemctl is-enabled --quiet NetworkManager; then
        echo -e "${CYAN}${BOLD}NetworkManager is not enabled. Installing and enabling NetworkManager...${RESET}"
        sudo pacman -S --noconfirm networkmanager
        sudo systemctl enable NetworkManager
        sudo systemctl start NetworkManager
        check_status "NetworkManager installed and enabled." "Failed to install or enable NetworkManager."
    else
        echo -e "${GREEN}${BOLD}NetworkManager is already enabled.${RESET}"
    fi
}

# Function to check and enable Bluetooth service
check_bluetooth() {
    if ! systemctl is-enabled --quiet bluetooth; then
        echo -e "${CYAN}${BOLD}Bluetooth service is not enabled. Installing and enabling Bluetooth service...${RESET}"
        sudo pacman -S --noconfirm bluez bluez-utils
        sudo systemctl enable bluetooth
        sudo systemctl start bluetooth
        check_status "Bluetooth service installed and enabled." "Failed to install or enable Bluetooth service."
    else
        echo -e "${GREEN}${BOLD}Bluetooth service is already enabled.${RESET}"
    fi
}

# Backup existing files
backup_file() {
    local file="$1"
    [[ -e "$file" ]] || return 0

    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}${BOLD}Backing up ${file} to ${backup}${RESET}"
    mv "$file" "$backup"
    check_status "Backup created" "Backup failed"
}

# Safely clone a repo
safe_clone() {
    local repo="$1"
    local dir="$2"

    if [ -d "$dir" ]; then
        echo -e "${YELLOW}${BOLD}Directory ${dir} already exists.${RESET}"
        read -rp "$(echo -e "${CYAN}${BOLD}Remove and clone again? (y/n):${RESET} ")" choice
        [[ $choice =~ ^[Yy](es)?$ ]] || {
            echo -e "${GREEN}${BOLD}Skipping clone of ${repo}${RESET}"
            return 0
        }
        rm -rf "$dir"
    fi

    git clone "$repo" "$dir"
    check_status "Cloned $repo" "Failed to clone $repo"
}

# Safely copy files/directories
safe_copy() {
	local src="$1"
    local dest="$2"
	local src_dir_name="$(basename "$1")"
	local dest_dir_name="$dest/$src_dir_name"

    [[ -e "$src" ]] || {
        echo -e "${RED}${BOLD}Error: Source ${src} does not exist.${RESET}"
        return 1
    }

    if [ -e "$dest_dir_name" ]; then
        echo -e "${YELLOW}${BOLD}${dest_dir_name} already exists.${RESET}"
        read -rp "$(echo -e "${CYAN}${BOLD}Do you want to backup and replace? (y/n):${RESET} ")" choice
        [[ $choice =~ ^[Yy](es)?$ ]] || {
            echo -e "${GREEN}${BOLD}Skipping copy of ${src}${RESET}"
            return 0
        }
        backup_file "$dest_dir_name"
    fi

    cp -r "$src" "$dest"
    check_status "Copied $src to $dest" "Failed to copy $src"
}

# Warning message
echo -e "${RED}${BOLD}WARNING:${RESET}Don't blindly run this script without knowing what it entails! This script is going to make changes on your system, before proceeding further, make sure you already backup up your current system."
echo -e "${CYAN}${BOLD}Please read and understand the script before proceeding.${RESET}"
read -rp "$(echo -e "${CYAN}${BOLD}Do you want to continue? (yes/no):${RESET} ")" choice
if [[ ! $choice =~ ^[Yy](es)?$ ]]; then
    echo -e "${RED}${BOLD}Script terminated.${RESET}"
    exit 1
fi

# Check if pacman is installed
check_pacman

# Check if yay or paru is already installed
if check_aur_helper; then
    # Determine which AUR helper is installed
    aur_helper=$(command -v yay || command -v paru)
else
    # AUR helper options
    aur_helpers=("yay" "paru")

    # Prompt user to choose AUR helper (default is yay)
    echo -e "${BOLD}Choose AUR helper (default is yay):${RESET}"
    select aur_helper in "${aur_helpers[@]}"; do
        case $aur_helper in
            "yay"|"paru")
                break
                ;;
            *)
                echo -e "${RED}${BOLD}Invalid option.${RESET} Please choose again."
                ;;
        esac
    done

    # Set default AUR helper to yay
    aur_helper=${aur_helper:-yay}

    # Install the AUR helper
    sudo pacman -S --needed git base-devel
    safe_clone https://aur.archlinux.org/$aur_helper.git $HOME/$aur_helper
    cd $HOME/$aur_helper
    makepkg -si
    cd $HOME
    check_status "$aur_helper is installed. Proceeding further..." "Failed to install $aur_helper."
fi

# Check and enable NetworkManager
check_network_manager

# Check and enable Bluetooth service
check_bluetooth

echo -e "Updating the system..."
$aur_helper -Syu --noconfirm

# Install Zsh
echo -e "${GREEN}${BOLD}Installing Zsh...${RESET}"
$aur_helper -S --noconfirm zsh

# Change the default shell to Zsh
echo -e "${GREEN}${BOLD}Changing default shell to Zsh...${RESET}"
chsh -s /bin/zsh
# Backup existing .zshrc if it exists
backup_file "$HOME/.zshrc"
touch "$HOME/.zshrc"

# Install Zsh plugins
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
echo -e "${GREEN}${BOLD}Cloning Zsh plugins: zsh-syntax-highlighting, zsh-autosuggestions, supercharge...${RESET}"
mkdir -p "$ZSH_PLUGIN_DIR"

safe_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
safe_clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
safe_clone https://github.com/zap-zsh/supercharge.git "$ZSH_PLUGIN_DIR/supercharge"

# List of packages to install
packages=(
    jq
    ripgrep
    alsa-utils
    sof-firmware
    pipewire
    wireplumber
    pipewire-alsa
    pipewire-pulse
    brightnessctl
    blueman
    hyprland
    hyprlock
    waybar
    xdg-utils
    xdg-user-dirs
    rofi-lbonn-wayland-git
    kitty
    neovim
    wl-clipboard
    thunar
    thunar-volman
    tumbler
    gvfs
    thefuck
    grim
    slurp
    swayimg
    dunst
    playerctl
    ffmpeg
    vlc
    gammastep
    lsd
    starship
    fastfetch
    cava
    btop
    swww
    waypaper
    firefox
    ttf-jetbrains-mono-nerd
    ttf-victor-mono-nerd
    adobe-source-han-sans-jp-fonts
    otf-opendyslexic-nerd
    nwg-look
    gradience
)

# Install the packages
echo -e "${CYAN}${BOLD}Installing the required packages...${RESET}"
$aur_helper -S --noconfirm "${packages[@]}"
check_status "Packages installed successfully." "Failed to install packages."

# Update user directories
echo -e "${GREEN}${BOLD}Updating user directories...${RESET}"
xdg-user-dirs-update

# Setup eww widgets
eww_deps=(
    rustup
    gtk3
    gtk-layer-shell
    pango
    gdk-pixbuf2
    libdbusmenu-gtk3
    cairo
    glib2
    gcc-libs
    glibc
)
echo -e "${CYAN}${BOLD}Installing dependecies for eww...${RESET}"
$aur_helper -S --noconfirm "${eww_deps[@]}"
check_status "All are dependecies installed." "Failed to dependecies for eww"

echo -e "${GREEN}${BOLD}Installing eww widgets...${RESET}"
safe_clone https://github.com/elkowar/eww $HOME/eww
cd $HOME/eww
cargo build --release --no-default-features --features=wayland
check_status "Eww build successful." "Failed to build Eww."
cd $HOME/eww/target/release
chmod +x ./eww
mkdir -p $HOME/.local/bin
cp eww $HOME/.local/bin
cd $HOME
echo -e "${GREEN}${BOLD}Eww widgets installed successfully.${RESET}"

for dir in $HYPRNEST_DIR/.config/*; do
	safe_copy $dir $HOME/.config
done
safe_copy $HYPRNEST_DIR/.zshrc $HOME
safe_copy $HYPRNEST_DIR/Pictures $HOME

echo -e "${GREEN}${BOLD}Installation complete :-)\n Please reboot your system. ${RESET}"
