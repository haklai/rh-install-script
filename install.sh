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


mv /etc/network/interfaces /etc/network/interfaces_bak

echo "Installing HA packages"
apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget vim net-tools fail2ban ufw sudo -y

nmcli connection modify eth0 connection.autoconnect yes
nmcli con mod eth0 ipv4.dns "8.8.8.8 8.8.4.4"

echo "Restart Network Manager"
systemctl restart NetworkManager

sleep 2

echo "Install docker"
curl -fsSL get.docker.com | sh

wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_x86_64.deb

echo "Install OS Agent"
sudo dpkg -i os-agent_1.6.0_linux_x86_64.deb

sudo wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb

echo "Install HA"
apt install ./homeassistant-supervised.deb

