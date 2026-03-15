# Getting alacritty to work
echo 'export TERM=xterm-256color' >> ~/.bashrc

# Systemd
mkdir -p /etc/systemd/system
sudo cp -r ./system/* /etc/systemd/system/

# Pufferpanel
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh?any=true | sudo bash
sudo apt update
sudo apt-get install pufferpanel
sudo pufferpanel user add
sudo systemctl enable --now pufferpanel

# Clear all kernel firewall rules
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
sudo iptables -X
sudo iptables -Z
sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD ACCEPT
sudo ip6tables -P OUTPUT ACCEPT
sudo ip6tables -F
sudo ip6tables -X
sudo ip6tables -Z

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install git
sudo apt update
sudo apt install git

# build Kokoros
sudo apt install build-essential libssl-dev pkg-config cmake libclang-dev libopus-dev libsonic-dev libpcaudio-dev
cd /home
git clone https://github.com/lucasjinreal/Kokoros
cd Kokoros
cargo build --release
sudo systemctl enable --now kokoros

# install grafana
sudo apt-get install -y apt-transport-https wget gnupg
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
sudo chmod 644 /etc/apt/keyrings/grafana.asc
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana
sudo systemctl enable --now grafana-server

# port map:
# 25565: Minecraft
# 8080: Pufferpanel
# 3000: Grafana
# 3001: Kokoros
