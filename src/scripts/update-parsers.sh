#!/bin/sh


# Copyright 2013-2020 Yikun Liu <cos.lyk@gmail.com>
#
# This program is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see http://www.gnu.org/licenses/.


# Set OS-dependent variables
OS_NAME=`uname -s`
CPU_ARCH=`uname -m`

if [ "$OS_NAME" = 'Darwin' ]; then       ### macOS
    DEST_DIR="$HOME/Library/Application Support/MoonPlayer"
    if [ "$CPU_ARCH" = "x86_64" ]; then  ## Intel
        LUX_SUFFIX="macOS_64-bit.tar.gz"
    else
        LUX_SUFFIX="macOS_ARM64.tar.gz"  ## Apple Silicon
    fi

elif [ "$OS_NAME" = 'Linux' ]; then      ### Linux
    XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
    DEST_DIR="$XDG_DATA_HOME/moonplayer"
    case "$CPU_ARCH" in
        i?86)
            LUX_SUFFIX="Linux_32-bit.tar.gz" ;;
        x86_64)
            LUX_SUFFIX="Linux_64-bit.tar.gz" ;;
        aarch64|aarch64|armv8|armv8?)
            LUX_SUFFIX="Linux_ARM64.tar.gz" ;;
        *)
            LUX_SUFFIX="Linux_ARM_v6.tar.gz" ;;
    esac
else
    echo "Unsupported system!"
    exit 0
fi

cd "$DEST_DIR"


# Set network tool
if which wget > /dev/null; then
    alias downloader="wget -q -O"
    alias fetcher="wget -q -O -"
else
    alias downloader="curl -s -L -o"
    alias fetcher="curl -s"
fi


# Set download source
if [ `date +"%z"` = "+0800" ]; then   # Mirror for China
    GITHUB_MIRROR="https://download.fastgit.org"
else
    GITHUB_MIRROR="https://github.com"
fi


# Set python
if which python3 > /dev/null; then
    PYTHON=python3
elif which python2 > /dev/null; then
    PYTHON=python2
else
    PYTHON=python
fi


# Define functions to check version
get_latest_version_github() {
    export PYTHONIOENCODING=utf8
    fetcher "https://api.github.com/repos/$1/releases/latest" | \
    $PYTHON -c "import sys, json; sys.stdout.write(json.load(sys.stdin)['tag_name'])"
}

get_current_version() {
    if [ -e "$DEST_DIR/version-$1.txt" ]; then
        cat "$DEST_DIR/version-$1.txt"
    fi
}

save_version_info() {
    echo "$2" > "version-$1.txt"
}


### Update lux
echo "\n-------- Checking lux's updates -------"

# Get latest lux version
CURRENT_VERSION=$(get_current_version "lux")
echo "Current version: $CURRENT_VERSION"

LATEST_VERSION=$(get_latest_version_github "iawia002/lux")
if [ -n "$LATEST_VERSION" ]; then
    echo "Latest version: $LATEST_VERSION"
else
    echo 'Error: Cannot get the latest version of lux. Please try again later.'
    exit 0
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Lux already up-to-date."
else
    # Download latest version
    echo "\n ------------ Updating lux -------------"
    echo "Downloading latest version..."
    URL="${GITHUB_MIRROR}/iawia002/lux/releases/download/${LATEST_VERSION}/lux_${LATEST_VERSION#v}_${LUX_SUFFIX}"
    echo "$URL"
    downloader lux.tar.gz "$URL"
    rm -f lux
    tar -xvf lux.tar.gz
    chmod a+x lux
    rm -f lux.tar.gz
    save_version_info "lux" "$LATEST_VERSION"
fi


### Update yt-dlp
echo "\n-------- Checking yt-dlp's updates -------"

# Get latest yt-dlp version
CURRENT_VERSION=$(get_current_version "yt-dlp")
echo "Current version: $CURRENT_VERSION"

LATEST_VERSION=$(get_latest_version_github "yt-dlp/yt-dlp")
if [ -n "$LATEST_VERSION" ]; then
    echo "Latest version: $LATEST_VERSION"
else
    echo 'Error: Cannot get the latest version of yt-dlp. Please try again later.'
    exit 0
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Yt-dlp already up-to-date."
else
    # Download latest version
    echo "\n ------------ Updating yt-dlp -------------"
    echo "Downloading latest version..."
    rm -f yt-dlp
    URL="$GITHUB_MIRROR/yt-dlp/yt-dlp/releases/download/$LATEST_VERSION/yt-dlp"
    echo "$URL"
    downloader yt-dlp "$URL"
    chmod a+x yt-dlp
    save_version_info "yt-dlp" "$LATEST_VERSION"
fi



### Update plugins
echo "\n----------- Checking plugin's updates ----------"

# Get current plugins' version
CURRENT_VERSION=$(get_current_version "plugins")
echo "Current version: $CURRENT_VERSION"

# Get latest plugins' version
LATEST_VERSION=$(get_latest_version_github "fangjiyuan/moonplayer-plugins")
if [ -n "$LATEST_VERSION" ]; then
    echo "Latest version: $LATEST_VERSION"
else
    echo 'Error: Cannot get the latest version of plugins. Please try again later.'
    exit 0
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Plugins already up-to-date."
else
    # Download latest version
    echo "\n-------------- Updating plugins --------------"
    echo "Downloading latest version..."
    URL="$GITHUB_MIRROR/fangjiyuan/moonplayer-plugins/releases/download/$LATEST_VERSION/plugins.zip"
    echo "$URL"
    downloader plugins.zip "$URL"
    unzip -o plugins.zip -d plugins
    rm -f plugins.zip
    save_version_info "plugins" "$LATEST_VERSION"
    echo "Finished. You need to restart MoonPlayer to load plugins."
fi

