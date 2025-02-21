#!/bin/bash

NST_AGENT_DIR="$HOME/.nst-agent"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if ! command -v sudo &> /dev/null; then
        echo "Error: this installer needs the ability to run commands as root.
              Please install sudo or run the script as root." >&2
        exit 1
    fi
    SUDO="sudo"
fi

# =======System=======
REQUIRED_MEM_MB=2048     # 2GB
REQUIRED_DISK_MB=10240   # 10GB
REQUIRED_RELEASE=22.04
REQUIRED_DISTRIBUTION="Ubuntu"
ARCH=$(uname -m)
OS_DISTRIBUTION=$(lsb_release -i --short)
OS_RELEASE=$(lsb_release -r --short)
AVAILABLE_MEM_MB=$(free -m | awk '/^Mem:/ {print $2}')
AVAILABLE_DISK_MB=$(df -m "/" | awk 'NR==2 {print $4}')


echo "Linux Distribution: $OS_DISTRIBUTION"
echo "OS Release: $OS_RELEASE"

if [ "$OS_DISTRIBUTION" != "$REQUIRED_DISTRIBUTION" ]; then
  echo "The OS release must be $REQUIRED_DISTRIBUTION"
  exit 1
fi

if awk -v a="$OS_RELEASE" -v b="$REQUIRED_RELEASE" 'BEGIN {exit (a >= b)}'; then
  echo "The OS release must be greater than or equal to $REQUIRED_RELEASE"
  exit 1
fi

if awk -v a="$AVAILABLE_MEM_MB" -v b="$REQUIRED_MEM_MB" 'BEGIN {exit (a >= b)}'; then
  echo "The memory must be greater than or equal to $REQUIRED_MEM_MB MB"
  exit 1
fi

if awk -v a="$AVAILABLE_DISK_MB" -v b="$REQUIRED_DISK_MB" 'BEGIN {exit (a >= b)}'; then
  echo "The system disk must be greater than or equal to $REQUIRED_DISK_MB MB"
  exit 1
fi

NO_KERNEL=false
NO_FONTS=false

TEMP=$(getopt -o '' --long no-kernel,no-fonts -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
    --no-kernel)
      NO_KERNEL=true
      shift
      ;;
    --no-fonts)
      NO_FONTS=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      exit 1
      ;;
  esac
done


$SUDO  apt-get update
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC $SUDO apt-get -y install tzdata
$SUDO apt install -y \
  x11vnc \
  unzip \
  wget \
  curl \
  jq \
  psmisc \
  supervisor \


install_tools(){
  case $OS_RELEASE in
    "24.04")
    $SUDO  apt-get install -y \
      libasound2t64 \
      libatk1.0-0t64 \
      libatk-bridge2.0-0t64 \
      libc6 \
      libcups2t64 \
      libdbus-1-3 \
      libexpat1 \
      libfontconfig1 \
      libgdk-pixbuf2.0-0 \
      libglib2.0-0t64 \
      libgtk-3-bin \
      libnspr4 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libstdc++6 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxrandr2 \
      libxrender1 \
      libxss1 \
      libxtst6 \
      ca-certificates \
      fonts-liberation \
      libnss3 \
      lsb-release \
      xdg-utils \
      libgbm-dev \
      libcurl3t64-gnutls
          ;;
    "22.04")
    $SUDO  apt-get install -y \
      libasound2 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libc6 \
      libcairo2 \
      libcups2 \
      libdbus-1-3 \
      libexpat1 \
      libfontconfig1 \
      libgcc1 \
      libgconf-2-4 \
      libgdk-pixbuf2.0-0 \
      libglib2.0-0 \
      libgtk-3-bin \
      libnspr4 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libstdc++6 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxrandr2 \
      libxrender1 \
      libxss1 \
      libxtst6 \
      ca-certificates \
      fonts-liberation \
      libappindicator1 \
      libnss3 \
      lsb-release \
      xdg-utils \
      libgbm-dev \
      libcurl3-gnutls
          ;;
      *)
        echo "Unsupported OS Release: $OS_RELEASE"
        exit 1
          ;;
  esac
}

install_tools

KERNEL_TYPE="nstchrome"
DEFAULT_KERNEL_MILESTONE=130
DEFAULT_KERNEL_VERSION="130-202412251400"

KERNEL_MILESTONE=""
KERNEL_VERSION=""
KERNEL_ARCH=""
AGENT_ARCH=""

if [[ "$ARCH" == "x86_64" ]]; then
    KERNEL_ARCH="amd64"
    AGENT_ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    KERNEL_ARCH="aarch64"
    AGENT_ARCH="arm64"
else
    echo "Not supported arch: $ARCH"
    exit 1
fi


get_last_kernel_version() {
  api_url="https://api.nstbrowser.io/api/v1/kernels/version/latest?arch=$KERNEL_ARCH&platform=2"
  response=$(curl -s --connect-timeout 30 "$api_url")

  kernel_milestone=$(echo "$response" | jq -r '.data[0].kernelMilestone' 2>/dev/null)
  kernel_version=$(echo "$response" | jq -r '.data[0].customVersion' 2>/dev/null)

  if [ -z "$kernel_version" ] || [ -z "$kernel_milestone" ]; then
    echo "Get latest kernel version failed, use default $DEFAULT_KERNEL_MILESTONE milestone and $DEFAULT_KERNEL_VERSION version"
    KERNEL_MILESTONE=$DEFAULT_KERNEL_MILESTONE
    KERNEL_VERSION=$DEFAULT_KERNEL_VERSION
  else
    echo "Get latest kernel version success, milestone: $kernel_milestone version: $kernel_version"
    KERNEL_MILESTONE=$kernel_milestone
    KERNEL_VERSION=$kernel_version
  fi
}

get_last_kernel_version

TAG_VERSION=$(echo "$KERNEL_VERSION" | cut -d'-' -f2)


AGENT_VERSION=""
NST_CHROME_DIR="$NST_AGENT_DIR/download/kernels/nstchrome/$KERNEL_TYPE-$KERNEL_MILESTONE-$KERNEL_VERSION"
NST_FONTS_DIR="$NST_AGENT_DIR/download/fonts"
NST_CHROME_FILENAME="$KERNEL_TYPE-$KERNEL_MILESTONE-$TAG_VERSION.linux-$KERNEL_ARCH.zip"

get_last_agent_version() {
  api_url="https://api.nstbrowser.io/api/v1/agents/version/latest/downloads"
  response=$(curl -s --connect-timeout 30 "$api_url")

  last_agent_version=$(echo "$response" | jq -r '.[0].versionName' 2>/dev/null)

  if [[ -z "$last_agent_version" ]]; then
    echo "Failed to parse the latest agent version from the response."
    exit 1
  fi

  if [[ "$last_agent_version" != v* ]]; then
    echo "Get not supported agent version: $last_agent_version"
    exit 1
  fi

  AGENT_VERSION=$last_agent_version
  echo "Get latest agent version success, agent version: $AGENT_VERSION"
}

get_last_agent_version

KERNEL_DOWNLOAD_URL="https://assets.nstbrowser.io/prod/kernel/$KERNEL_TYPE-$KERNEL_MILESTONE/$TAG_VERSION/$NST_CHROME_FILENAME"
AGENT_DOWNLOAD_URL="https://github.com/Nstbrowser/nstbrowser-agent-setup/releases/download/$AGENT_VERSION/agent-linux-$AGENT_ARCH-$AGENT_VERSION.tar.gz"



init() {
  rm -rf "/tmp/$NST_CHROME_FILENAME" /tmp/fonts.zip "$NST_AGENT_DIR/download/kernels/nstchrome" "$NST_AGENT_DIR/download/fonts"

  mkdir -p "$NST_AGENT_DIR/download/kernels/nstchrome"
  mkdir -p "$NST_FONTS_DIR"
}

download_agent() {
  echo "Start downloading agent..."
  wget -O "/tmp/agent.tar.gz" "$AGENT_DOWNLOAD_URL"
  if [ $? -ne 0 ]; then
    echo "Download agent failed. Please check your network connection."
    return 1
  fi

  tar -xzvf "/tmp/agent.tar.gz" --transform="s/agent_$AGENT_ARCH/agent/"  -C ./
  echo "Download agent success"
  rm -rf "/tmp/agent.tar.gz"
  return 0
}


download_kernel() {
  if [ "$NO_KERNEL" = "true" ]; then
    return 0
  fi

  echo "Start downloading $KERNEL_MILESTONE kernel..."
  zip_file="/tmp/$NST_CHROME_FILENAME"

  wget -O "$zip_file" "$KERNEL_DOWNLOAD_URL"
  if [ $? -ne 0 ]; then
    echo "Download kernel failed. Please check your network connection."
    return 1
  fi

  unzip -q "$zip_file" -d "$NST_CHROME_DIR"
  rm -rf "$zip_file"
  echo "Download $KERNEL_MILESTONE kernel success"
}

download_fonts() {
  if [ "$NO_FONTS" = "true" ]; then
    return 0
  fi

  echo "Start downloading fonts..."
  fonts_url="https://assets.nstbrowser.io/public/font/fonts.zip"
  wget -O "/tmp/fonts.zip" "$fonts_url"
  if [ $? -ne 0 ]; then
    echo "Failed to download fonts. Please check your network connection "
    return 1
  fi
  unzip -q "/tmp/fonts.zip" -d "$NST_FONTS_DIR"
  rm -rf /tmp/fonts.zip
  echo "Download fonts success"
}

do_install() {
  init

  if ! download_kernel; then
    exit 1
  fi

  if ! download_agent; then
    exit 1
  fi

  if ! download_fonts; then
    exit 1
  fi

  echo "agent install success!"
}

do_install
