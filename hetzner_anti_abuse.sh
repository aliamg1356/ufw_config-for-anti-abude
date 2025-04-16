#!/bin/bash

# UFW Configuration Script for Ubuntu

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Find SSH port
ssh_port=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}')
if [ -z "$ssh_port" ]; then
    ssh_port=22
    echo "SSH port not found in config, using default port 22."
else
    echo "Found SSH port: $ssh_port"
fi

# Ask if TCP or UDP for SSH port
echo "Is the SSH port TCP or UDP? [tcp/udp] (default: tcp):"
read port_type
port_type=${port_type:-tcp}  # Set default to tcp if empty
port_type=$(echo "$port_type" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase

# Validate port type
if [[ "$port_type" != "tcp" && "$port_type" != "udp" ]]; then
    echo "Invalid input, using TCP as default."
    port_type="tcp"
fi

# Allow SSH port in UFW
echo "Allowing SSH port ($ssh_port/$port_type) in UFW..."
ufw allow $ssh_port/$port_type

# Ask if SSH connections should be limited
echo "Do you want to limit the number of SSH connections? [y/n] (default: n):"
read limit_ssh
limit_ssh=${limit_ssh:-n}  # Set default to n if empty
limit_ssh=$(echo "$limit_ssh" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase

if [[ "$limit_ssh" == "y" ]]; then
    echo "Limiting SSH connections..."
    ufw limit $ssh_port/$port_type
fi

# Add outbound blocking rules
echo "Adding outbound blocking rules..."
ufw deny out from any to 10.0.0.0/8
ufw deny out from any to 172.16.0.0/12
ufw deny out from any to 192.168.0.0/16
ufw deny out from any to 100.64.0.0/10
ufw deny out from any to 198.18.0.0/15
ufw deny out from any to 169.254.0.0/16
ufw deny out from any to 141.101.78.0/23
ufw deny out from any to 173.245.48.0/20
ufw deny out from any to 0.0.0.0/8
ufw deny out from any to 127.0.0.0/8
ufw deny out from any to 127.0.53.53
ufw deny out from any to 192.0.0.0/24
ufw deny out from any to 192.0.2.0/24 
ufw deny out from any to 192.88.99.0/24
ufw deny out from any to 198.51.100.0/24
ufw deny out from any to 203.0.113.0/24
ufw deny out from any to 224.0.0.0/3
ufw deny out from any to 240.0.0.0/4
ufw deny out from any to 255.255.255.255
ufw deny out from any to 102.230.9.0/24
ufw deny out from any to 102.233.71.0/24
ufw deny out from any to 102.236.0.0/16


# Prompt for additional ports
echo "Do you want to open additional ports? (y/n)"
read answer

while [ "$answer" = "y" ] || [ "$answer" = "Y" ]; do
    echo "Please enter the port number to open (e.g., 80 or 443):"
    read port
    
    # Validate port number
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        # Ask for TCP or UDP
        echo "Is this port TCP or UDP? [tcp/udp] (default: tcp):"
        read additional_port_type
        additional_port_type=${additional_port_type:-tcp}  # Set default to tcp if empty
        additional_port_type=$(echo "$additional_port_type" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
        
        # Validate port type
        if [[ "$additional_port_type" != "tcp" && "$additional_port_type" != "udp" ]]; then
            echo "Invalid input, using TCP as default."
            additional_port_type="tcp"
        fi
        
        echo "Opening port $port/$additional_port_type..."
        ufw allow $port/$additional_port_type
    else
        echo "Invalid port number."
    fi
    
    echo "Do you want to open another port? (y/n)"
    read answer
done

# Enable UFW firewall
echo "Enabling UFW firewall..."
ufw --force enable

# Show active rules
echo "Current UFW rules:"
ufw status verbose

echo "Script completed successfully."
