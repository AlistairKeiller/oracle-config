#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (sudo ./install.sh)" >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(eval echo "~$REAL_USER")

echo "Clearing all kernel firewall rules"
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -Z
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -F
ip6tables -X
ip6tables -Z

echo "Configuring alacritty"
echo 'export TERM=xterm-256color' >> ~/.bashrc

echo "Setting up systemd"
mkdir -p /etc/systemd/system
cp -r ./system/* /etc/systemd/system/

echo "Installing Pufferpanel"
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh?any=true | bash
apt update
apt-get install pufferpanel
pufferpanel user add
systemctl enable --now pufferpanel

echo "Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "Installing Git"
apt update
apt install git

echo "Building Kokoros"
apt install build-essential libssl-dev pkg-config cmake libclang-dev libopus-dev libsonic-dev libpcaudio-dev
cd /home
git clone https://github.com/lucasjinreal/Kokoros
cd Kokoros
cargo build --release
systemctl enable --now kokoros

echo "Installing Grafana"
apt-get install -y apt-transport-https wget gnupg
mkdir -p /etc/apt/keyrings
wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
chmod 644 /etc/apt/keyrings/grafana.asc
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install grafana
systemctl enable --now grafana-server

echo "Installing TDengine"
wget https://downloads.tdengine.com/tdengine-tsdb-oss/3.4.0.9/tdengine-tsdb-oss-3.4.0.9-linux-arm64.tar.gz
tar -zxvf tdengine-tsdb-oss-3.4.0.9-linux-arm64.tar.gz
cd tdengine-tsdb-oss-3.4.0.9
./install.sh
systemctl enable --now taosd

echo "Port map:"
echo "25565: Minecraft"
echo "8080: Pufferpanel"
echo "3000: Grafana"
echo "3001: Kokoros"
