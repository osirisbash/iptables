#!/bin/sh

IPTABLES="/usr/sbin/iptables"

# Variables loopback local
IFACE_LO="lo"
IP_FW_LO="127.0.0.1"

NET_ALL_INTERNE="192.168.0.0/16"

# Variables pour la connexion Internet
IFACE_INTERNET="ens4"
IP_FW_INTERNET="192.168.1.1"


IFACE_PDT="ens6"
IFACE_VLAN_PDT_ADMIN="ens6.30"
IP_FW_VLAN_PDT_ADMIN="192.168.30.1"
NET_PDT_ADMIN="192.168.30.0/24"
# Nous vidons toutes les chaines
iptables -F

# Nous supprimons les chaines non standards
$IPTABLES -X

# Par defaut tout est ferme
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

# reinitialisation table NAT
$IPTABLES -t nat -F
$IPTABLES -t nat -X

$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES-t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT

# Translation d'adresse pour tout ce qui sort vers l'internet
$IPTABLES -t nat -A POSTROUTING -o ens4 -j MASQUERADE

# La machine locale est sure
$IPTABLES -A INPUT  -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Resolution DNS pour le firewall
$IPTABLES -A INPUT  -i ens4 --protocol udp --source-port 53 -j ACCEPT
$IPTABLES-A OUTPUT -o ens4 --protocol udp --destination-port 53 -j ACCEPT
$IPTABLES-A INPUT  -i ens4 --protocol tcp --source-port 53 -j ACCEPT
$IPTABLES-A OUTPUT -o ens4 --protocol tcp --destination-port 53 -j ACCEPT 

# Resolution DNS pour les machines du LAN
$IPTABLES -A FORWARD -i ens4 -o ens6.30 --protocol udp --source-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i ens6.30 -o ens4 --protocol udp --destination-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i ens4 -o ens6.30 --protocol tcp --source-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i ens6.30 -o ens4 --protocol tcp --destination-port 53 -j ACCEPT 

# connexions Firewall-Internet (www)
$IPTABLES -A OUTPUT -p tcp --dport 80  -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 443 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT  -p tcp --sport 80  -i ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT  -p tcp --sport 443 -i ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT

# connexions LAN-Internet (www)
#$IPTABLES -A FORWARD -p tcp --dport 80  -i ens6.30 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#$IPTABLES -A FORWARD -p tcp --dport 443 -i ens6.30 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#$IPTABLES -A FORWARD -p tcp --sport 80  -i ens4 -o ens6.30 -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPTABLES -A FORWARD -p tcp --sport 443 -i ens4 -o ens6.30 -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPTABLES -A FORWARD -p tcp --dport 80,443  -i ens6.30 -o ens4 -m multiport -j ACCEPT
$IPTABLES -A FORWARD -p tcp --dport 80,443  -i ens4 -o ens6.30 -m multiport -j ACCEPT


# Fin du fichier

