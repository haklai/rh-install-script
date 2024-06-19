#!/bin/bash

echo "Updating and upgrading OS to latest kernel and packages"
apt update -qy
apt upgrade -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
apt autoclean -qy
apt upgrade -y
apt autoremove -y

# Clean up old journalctl logs
echo "Cleaning up old journalctl logs"
journalctl --flush --rotate --vacuum-time=1s

# Create SWAP
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
sysctl vm.swappiness=50

# Prepare Network
echo "Prepare for Network Manager"
mv /etc/network/interfaces /etc/network/interfaces_bak

echo "Installing HA packages"
apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget vim net-tools fail2ban ufw sudo vim -y

echo "Configure Network Manager"
nmcli connection modify eth0 connection.autoconnect yes
nmcli con mod eth0 ipv4.dns "8.8.8.8 8.8.4.4"
systemctl restart NetworkManager

sleep 2

# Setup Firewall
echo "Configure FireWall"
wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
chmod +x /usr/local/bin/ufw-docker
ufw-docker install
systemctl restart ufw

ufw allow ssh
ufw allow 8123
ufw allow in on hassio to any
yes | ufw enable

# Install Home Assistant Supervised
echo "Install docker"
curl -fsSL get.docker.com | sh

echo "Configure FireWall for docker"
wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
chmod +x /usr/local/bin/ufw-docker
ufw-docker install
ufw reload

echo "Install OS Agent"
wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_x86_64.deb
sudo dpkg -i os-agent_1.6.0_linux_x86_64.deb

echo "Prepare one time script"
wget https://raw.githubusercontent.com/haklai/rh-install-script/main/one_time_script.service
wget https://raw.githubusercontent.com/haklai/rh-install-script/main/one_time_script.sh
mv one_time_script.service /etc/systemd/system/
mv one_time_script.sh /usr/local/bin/one_time_script.sh
chmod +x /usr/local/bin/one_time_script.sh
systemctl enable one_time_script.service

echo "Install HA"
sudo wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
apt install ./homeassistant-supervised.deb && sleep 10 && reboot

