#!/usr/bin/env bash

remote_host=$1
keypath=$HOME/.ssh/rsa
remote_user=$2
remote_password=$3
local_user=$(whoami)

set -e

echo "Creating ssh Key for Remote Host: ${remote_host}"

ssh-keygen -t rsa -C "sze151800@stud.gibb.ch" -b 4096 -f "${keypath}" -N ""

sshpass -p "${remote_password}" ssh-copy-id -o  StrictHostKeyChecking=no -i "${keypath}.pub" "${remote_user}@${remote_host}"

echo "Created and Copied SSH Key"
echo "SSH into Server to create SSH Key"

ssh "${remote_user}@${remote_host}" 'ssh-keygen -t rsa -C "vmadmin@server" -b 4096'

echo "Created ssh Key on Server"
echo "MOdifingng Net Plan Config on Server"

ssh "${remote_user}@${remote_host}" <<  EOF
if command -v netplan >/dev/null 2>&1; then
    echo "✅ Netplan is installed"
else
    echo "Netplan is not installed"
    echo "Installing Netplan"
    echo "sml12345" | sudo -S apt update
    echo "sml12345" | sudo -S apt install -y netplan.io

fi

echo "sml12345" | sudo -S  mkdir -p /etc/netplan
cd /etc/netplan
cat << NETPLAN_EOF | sudo tee /etc/netplan/01-eth1.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      dhcp4: no
      dhcp6: no
  bridges:
    br1:
      interfaces: [eth1]
      addresses: [192.168.30.1/24]
      mtu: 1500
      parameters:
        stp: false
        forward-delay: 4
      dhcp4: no
      dhcp6: no
NETPLAN_EOF

echo "sml12345" | sudo -S netplan apply
echo "sml12345" | sudo -S  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "sml12345" | sudo -S iptables -A FORWARD -i eth0 -o br1 -m state \
    --state NEW,RELATED,ESTABLISHED -j ACCEPT
echo "sml12345" | sudo -S iptables -A FORWARD -i br1 -o eth0 -j ACCEPT
echo "sml12345" | sudo -S tee -a /etc/sysctl.conf <<< "net.ipv4.ip_forward=1"
echo "sml12345" | sudo -S  sysctl -p
echo "sml12345" | sudo -S apt update -y 
echo "sml12345" |  sudo -S apt install iptables-persistent
EOF
echo "Configured Netplan on Server"
echo "Trying to Ping VM inside Server to test"
if ping -c 1 -W 2 "192.168.30.1" >/dev/null 2>&1; then
	echo "Succesfully configured Bridge"
else
	echo "Something went wrong"
	echo "sml12345" | sudo apt install tracerroute -y
	traceroute 192.168.30.1
fi 

echo "Script finished" 

