#!/bin/sh
PUBLIC_IP=X.X.X.X
# Delete all rules before
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Block all incoming connections and allow all outgoing connection
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT ACCEPT

# FORWARD authorization of INPUT / OUTPUT for VMs (Proxmox)
iptables -t filter -A FORWARD -o vmbr0 -j ACCEPT
iptables -t filter -A FORWARD -i vmbr0 -j ACCEPT

#Traffic redirection permission for vmbr1 from vmbr0 (Proxmox)
iptables -t nat -A POSTROUTING -o vmbr0 -j MASQUERADE

# Don't break the current/active connections
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Enable Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Log packets input and forward :
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG

# Allow ICMP
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A INPUT  -p icmp  -j ACCEPT

# Allow INPUT
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i vmbr1 -s $PUBLIC_IP -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i vmbr1 -s $PUBLIC_IP -p tcp --dport 443 -j ACCEPT

# NAT Rules
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 443 -j DNAT --to 192.168.0.4:443
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 80 -j DNAT --to 192.168.0.4:80

# Backup rules
iptables-save -c > /etc/iptables.rules
