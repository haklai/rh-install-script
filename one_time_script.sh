#!/bin/bash
# /usr/local/bin/one_time_script.sh

echo "This script runs once after a reboot."
# Add your actual script logic here

sleep 10

ha addons install a0d7b954_tailscale

# Remove the systemd service file to prevent the script from running again
rm -f /etc/systemd/system/one_time_script.service
systemctl daemon-reload
