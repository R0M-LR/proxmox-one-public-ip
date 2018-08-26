#!/bin/sh
# Suppression des règles actuelles :
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Blocage de toutes les connexions en entrée et autorisation de toutes les connexions en sortie :
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT ACCEPT

# Autorisation FORWARD des INPUT/OUTPUT pour les VMs (Proxmox)
iptables -t filter -A FORWARD -o vmbr0 -j ACCEPT
iptables -t filter -A FORWARD -i vmbr0 -j ACCEPT

#Autorisation de la redirection de trafic de vmbr1 en provenance de vmbr0 (Proxmox)
iptables -t nat -A POSTROUTING -o vmbr0 -j MASQUERADE

# Don't break the current/active connections
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Autoriser le Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Log des paquets en entrée et en forward :
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG

# Allow ICMP
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A INPUT  -p icmp  -j ACCEPT

# Allow INPUT
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i vmbr1 -s 91.121.174.23 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i vmbr1 -s 91.121.174.23 -p tcp --dport 443 -j ACCEPT

# NAT Rules
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 443 -j DNAT --to 192.168.0.4:443
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 80 -j DNAT --to 192.168.0.4:80

# Sauvegarde des régles
iptables-save -c > /etc/iptables.rules
