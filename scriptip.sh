#!/bin/sh

iptables -P INPUT DROP 
iptables -P OUTPUT DROP 
iptables -P FORWARD DROP



# LO
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A FORWARD -i lo -j ACCEPT
iptables -A FORWARD -o lo -j ACCEPT


iptables -A FORWARD -t filter -m state --state ESTABLISHED,RELATED 
 
 
# PING VERS PASSERELLE

iptables -A INPUT -t filter -s 192.168.30.0/24 -d 192.168.30.1 -i ens6.30 -p icmp --icmp-type echo-request -j ACCEPT 
iptables -A OUTPUT -t filter -p icmp --icmp-type echo-reply -j ACCEPT 
iptables -A INPUT -t filter -s 195.168.1.0/24 -d 195.168.1.1 -i ens4 -p icmp --icmp-type echo-request -j ACCEPT


#POSTROUTING  
iptables -A POSTROUTING -t nat -o ens4 -j MASQUERADE 
#iptables ­t nat ­A POSTROUTING ­-s <adrIP ou réseau à masquer> ­-o <interface ext.> -­j MASQUERADE
iptables -A POSTROUTING -t nat -s 192.168.30.0/24 -j SNAT --to-source 192.168.1.1 

# ICMP
iptables -A FORWARD -t filter -s 192.168.30.0/24 -i ens6.30 -o ens4 -p icmp --icmp-type echo-request -j ACCEPT 
iptables -A FORWARD -t filter -i ens4 -o ens6.30 -p icmp --icmp-type echo-reply -j ACCEPT 


# HTTP & HTTPS
iptables -A FORWARD -t filter -s 192.168.30.0/24 -i ens6.30 -o ens4 -p tcp  --dport 80 -j ACCEPT 
iptables -A FORWARD -t filter -s 192.168.30.0/24 -i ens6.30 -o ens4 -p tcp  --dport 443 -j ACCEPT 
iptables -A FORWARD -t filter -i ens4 -d 192.168.30.0/24 -p tcp --sport 443 -j ACCEPT 
iptables -A FORWARD -t filter -i ens4 -d 192.168.30.0/24 -p tcp --sport 80 -j ACCEPT
    
$IPTABLES -A FORWARD -p TCP -i ens6.30 -o ens4 -s 192.168.30.5 -m multiport --dport 80,443 -j ACCEPT -j LOG --log-prefix "Surf Web:   



