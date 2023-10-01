function get_commit_version() {
    xml_data=$(curl -s "https://github.com/hiddify/$1/commits/main.atom")
    latest_commit_date=$(echo "$xml_data" | grep -m 1 '<updated>' | awk -F'>|<' '{print $3}')
    # COMMIT_URL=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main | jq -r .object.url)
    # latest_commit_date=$(curl -s $COMMIT_URL | jq -r .committer.date)
    echo "${latest_commit_date:5:11}"
}

function get_pre_release_version() {
    lastversion "$1" --pre --at github
}

function get_release_version() {
    # COMMIT_URL=https://api.github.com/repos/hiddify/$1/releases/latest
    # VERSION=$(curl -s --connect-timeout 1 $COMMIT_URL | jq -r .tag_name)
    VERSION=$(curl -sI https://github.com/hiddify/$1/releases/latest | grep -i location | rev | awk -F/ '{print $1}' | rev)
    VERSION=${VERSION//v/}
    echo "${VERSION//$'\r'/}"
}
function hiddifypanel_path() {
    python3 -c "import site, os; package_name = 'hiddifypanel'; package_path = next((os.path.join(p, package_name) for p in site.getsitepackages() if os.path.isdir(os.path.join(p, package_name))), None); print(package_path)"
}
function get_installed_panel_version() {
    cat "$(hiddifypanel_path)/VERSION"
}
function get_installed_config_version() {
    cat /opt/hiddify-server/VERSION
}

function get_package_mode() {
    cd /opt/hiddify-server/hiddify-panel
    python3 -m hiddifypanel all-configs | jq -r ".hconfigs.package_mode"
}

function error() {
    echo -e "\033[91m$1\033[0m" >&2
}

function add_DNS_if_failed() {
    # Domain to check
    DOMAIN="yahoo.com"

    # Use dig to resolve the domain
    dig +short $DOMAIN >/dev/null 2>&1

    # Check the exit status of the dig command
    if [ $? -ne 0 ]; then
        echo "Dig failed to resolve $DOMAIN! Adding nameserver 8.8.8.8 to /etc/resolv.conf..."
        # Check if 8.8.8.8 is already in the file to avoid appending it multiple times
        grep -q "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
        # else
        # echo "Dig resolved $DOMAIN successfully!"
    fi

}

function disable_ansi_modes() {
    echo -e "\033[?25l"
    echo -e "\e[?1003l"
    #echo -e '\033c'
    echo -e '\e[?25h'
    tput sgr0
    pkill -9 dialog
}

function update_progress() {
    add_DNS_if_failed
    #title="\033[92m\033[1m${1^}\033[0m\033[0m"
    title="${1^}"
    text="$2"
    percentage="$3"
    echo -e "XXX\n$percentage\n$title\n$text\nXXX"
}

function install_package() {
    for package in "$@"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            # The package is not installed, install it
            apt install -y "$package"
            if [ $? -ne 0 ]; then
                apt --fix-broken install -y
                apt update
                apt install -y "$package"
            fi
            # else
            # The package is installed, do nothing
            # echo "$package is already installed"
        fi
    done
}

function remove_package() {
    for package in "$@"; do
        if dpkg -l | grep -q "^ii  $package"; then
            apt remove -y "$package"
        fi
    done
}

function is_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

function msg_with_hiddify() {
    text=$(
        cat <<END
                                  ▓▓▓
                                ▓▓▓▓▓
                           ▓▓▓       
                         ▓▓▓▓▓  ▓▓▓▓▓
                    ▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓
                 ▓▓▓▓▓▓  ▓▓▓▓▓  ▓▓▓▓▓
END
    )
    msg "$text \n\n$1"

}

function msg() {
    NEWT_COLORS='title=blue, textbox=blue, border=blue, button=black,blue' whiptail --title Hiddify --msgbox "$1" 0 60
}

function hiddify_api() {
    data=$(
        cd /opt/hiddify-server/hiddify-panel
        python3 -m hiddifypanel "$1"
    )
    echo "$data"
    return 0
}
