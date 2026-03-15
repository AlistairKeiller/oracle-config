#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)" >&2
  exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(eval echo "~$REAL_USER")
ARCH=$(dpkg --print-architecture)

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

for port in 25565 8080 3000 3001; do
  iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
  ip6tables -I INPUT -p tcp --dport "$port" -j ACCEPT
done

netfilter-persistent save

# Alacritty
grep -q 'TERM=xterm-256color' "$REAL_HOME/.bashrc" 2>/dev/null || \
  echo 'export TERM=xterm-256color' >> "$REAL_HOME/.bashrc"

# Systemd units
mkdir -p /etc/systemd/system
cp -r ./system/* /etc/systemd/system/
systemctl daemon-reload

# Pufferpanel
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh?any=true | bash
apt-get update -y
apt-get install -y pufferpanel
pufferpanel user add
systemctl enable --now pufferpanel

# Rust
sudo -u "$REAL_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'

# Git + build deps
apt-get install -y git build-essential libssl-dev pkg-config cmake libclang-dev libopus-dev libsonic-dev libpcaudio-dev

# Kokoros
git clone https://github.com/lucasjinreal/Kokoros /home/Kokoros || true
sudo -u "$REAL_USER" bash -c 'source "$HOME/.cargo/env" && cd /home/Kokoros && cargo build --release'
systemctl enable --now kokoros

# Grafana
apt-get install -y apt-transport-https wget gnupg
mkdir -p /etc/apt/keyrings
wget -qO /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
chmod 644 /etc/apt/keyrings/grafana.asc
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y grafana
systemctl enable --now grafana-server

# TDengine
TD_VER="3.4.0.9"
wget -q "https://downloads.tdengine.com/tdengine-tsdb-oss/${TD_VER}/tdengine-tsdb-oss-${TD_VER}-linux-${ARCH}.tar.gz"
tar -zxf "tdengine-tsdb-oss-${TD_VER}-linux-${ARCH}.tar.gz"
cd "tdengine-tsdb-oss-${TD_VER}" && ./install.sh && cd -
rm -rf "tdengine-tsdb-oss-${TD_VER}"*
systemctl enable --now taosd

echo "Port map:"
echo "  25565: Minecraft"
echo "  8080:  Pufferpanel"
echo "  3000:  Grafana"
echo "  3001:  Kokoros"