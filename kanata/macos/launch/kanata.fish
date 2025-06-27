#!/usr/bin/env fish
# kanata.fish — manage Kanata and Karabiner VHID services via launchctl

# Paths to LaunchDaemon targets
set -l PL_KANATA /Library/LaunchDaemons/com.example.kanata.plist
set -l PL_VHIDD /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
set -l PL_VHIDM /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist

# Local source copies (adjust these paths)
set -l SRC_ROOT $HOME/.config/keymaps/kanata/macos/launch/
set -l SRC_KANATA $SRC_ROOT/com.example.kanata.plist
set -l SRC_VHIDD $SRC_ROOT/com.example.karabiner-vhiddaemon.plist
set -l SRC_VHIDM $SRC_ROOT/com.example.karabiner-vhidmanager.plist

# Launchctl labels (no 'system/' prefix)
set -l L_KANATA com.example.kanata
set -l L_VHIDD com.example.karabiner-vhiddaemon
set -l L_VHIDM com.example.karabiner-vhidmanager

function usage
    echo ""
    echo "Usage: sudo $(status current-filename) <command>"
    echo ""
    echo "Commands:"
    echo "  init      Copy .plist files to /Library/LaunchDaemons (overwrites existing)"
    echo "  enable    Load and configure services to start at boot"
    echo "  disable   Unload and prevent services from starting at boot"
    echo "  status    Show current service status"
    echo ""
    exit 1
end

# Root check
if test (id -u) -ne 0
    echo "Run as root: sudo $(status current-filename) ..." >&2
    exit 1
end

# Validate subcommand
set -l valid init enable disable start stop restart status
if not contains $argv[1] $valid
    usage
end

# Function: copy and install plist file
function install_plist
    set dest $argv[1]
    set src $argv[2]

    echo "Installing plist: $(basename $dest)"
    if not test -f $src
        echo "Source plist not found: $src" >&2
        exit 1
    end

    cp $src $dest
    chmod 644 $dest
    chown root:wheel $dest
end

# Function: launchctl wrapper
function manage_service
    set cmd $argv[1]
    set label $argv[2]
    set plist $argv[3]

    switch $cmd
        case enable
            launchctl bootout system $plist >/dev/null 2>&1
            launchctl bootstrap system $plist
        case disable
            launchctl bootout system $plist
        case status
            launchctl print system/$label
    end
end

# Dispatch commands
switch $argv[1]
    case init
        install_plist $PL_KANATA $SRC_KANATA
        install_plist $PL_VHIDD $SRC_VHIDD
        install_plist $PL_VHIDM $SRC_VHIDM
        echo "Plist files installed"
        exit 0
    case enable
        manage_service enable $L_VHIDD $PL_VHIDD
        manage_service enable $L_VHIDM $PL_VHIDM
        manage_service enable $L_KANATA $PL_KANATA
        echo "All services enabled"
    case disable
        manage_service disable $L_KANATA $PL_KANATA
        manage_service disable $L_VHIDM $PL_VHIDM
        manage_service disable $L_VHIDD $PL_VHIDD
        echo "All services disabled"
    case status
        echo "=== Status: Kanata ==="
        manage_service status $L_KANATA $PL_KANATA
        echo "=== Status: Karabiner VHID Daemon ==="
        manage_service status $L_VHIDD $PL_VHIDD
        echo "=== Status: Karabiner VHID Manager ==="
        manage_service status $L_VHIDM $PL_VHIDM
    case '*'
        usage
end
