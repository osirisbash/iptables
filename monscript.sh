#!/bin/sh

IPTABLES="/usr/sbin/iptables"

# Variables loopback local
IFACE_LO="lo"
IP_FW_LO="127.0.0.1"

NET_ALL_INTERNE="192.168.0.0/16"

# Variables pour la connexion Internet
IFACE_INTERNET="ens4"
IP_FW_INTERNET="192.168.1.1"

# Variables Windows Server
IFACE_VLAN_SERVER="ens6.30"
IP_FW_VLAN_SERVER="192.168.30.1"

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
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT

# Translation d'adresse pour tout ce qui sort vers l'internet
$IPTABLES -t nat -A POSTROUTING -o IFACE_INTERNET -j MASQUERADE
#
$IPTABLES -A FORWARD -m state --state ESTABLISHED -j ACCEPT

# La machine locale est sure
$IPTABLES -A INPUT  -i IFACE_LO -j ACCEPT
$IPTABLES -A OUTPUT -o IFACE_LO -j ACCEPT

# Resolution DNS pour le firewall
$IPTABLES -A INPUT  -i IFACE_INTERNET -p UDP --source-port 53 -j ACCEPT
$IPTABLES -A OUTPUT -o IFACE_INTERNET -p UDP --destination-port 53 -j ACCEPT
$IPTABLES -A INPUT  -i IFACE_INTERNET -p TCP --source-port 53 -j ACCEPT
$IPTABLES -A OUTPUT -o IFACE_INTERNET -p TCP --destination-port 53 -j ACCEPT 

# Resolution DNS pour les machines du LAN
$IPTABLES -A FORWARD -i IFACE_INTERNET -o IFACE_VLAN_SERVER -p UDP --source-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i IFACE_VLAN_SERVER -o IFACE_INTERNET -p UDP --destination-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i IFACE_INTERNET -o IFACE_VLAN_SERVER -p TCP --source-port 53 -j ACCEPT
$IPTABLES -A FORWARD -i IFACE_VLAN_SERVER -o IFACE_INTERNET -p TCP --destination-port 53 -j ACCEPT 

# connexions Firewall-Internet (www)
$IPTABLES -A OUTPUT -o IFACE_INTERNET -p TCP -m multiport --dport 80,443 -j ACCEPT
$IPTABLES -A INPUT -i IFACE_INTERNET -p TCP -m multiport --sport 80,443 -j ACCEPT


#Connexion LAN - Internet
$IPTABLES -A FORWARD -i IFACE_VLAN_SERVER -o IFACE_INTERNET -p tcp -m multiport --dport 80,443 -j ACCEPT
$IPTABLES -A FORWARD -i IFACE_INTERNET -o IFACE_VLAN_SERVER -p tcp -m multiport --dport 80,443 -j ACCEPT


# Fin du fichier

