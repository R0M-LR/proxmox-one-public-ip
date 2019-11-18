# Proxmox with one public IP address
At tthe first, you add this bloc into your /etc/network/interface :   
```bash
auto vmbr1
iface vmbr1 inet static
	address  10.0.0.1
	netmask  255.255.255.0
	bridge_ports none
	bridge_stp off
	bridge_fd 0
```
Uncomment this line into /etc/sysctl.conf   
```bash
net.ipv4.ip_forward = 1
```
Add this rule info iptables   
```bash
iptables -t nat -A POSTROUTING -s '10.0.0.0/24' -o vmbr0 -j MASQUERADE
```
After, you need to change network card of VMs with vmbr1 and add 10.0.0.1 for gateway.   
At this state, your VMs have internet connection.    
For port translation, you need to add 2 lines in iptables, 1 line for opening port and 1 line to redirect public port to private port on VM.   


## For persistant rules
```bash
apt-get install iptables-persistent
```
Persistante configuration are store in this 2 files : /etc/iptables/rules.v4 for IPV4 and /etc/iptables/rules.v6 for IPV6
```bash
nano /etc/iptables/rules.v4
```
