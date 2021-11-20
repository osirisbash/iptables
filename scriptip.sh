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

# Definition de la politique par defaut
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

# Autorisation du trafic pour l'interface locale de Loopback
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $IP_FW_LO -j ACCEPT
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $NET_ALL_INTERNE -j ACCEPT
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $IP_FW_INTERNET -j ACCEPT


# NAT pour les echanges entre le proxy Web et Internet
$IPTABLES -t nat -A POSTROUTING -o $IFACE_DMZOUT -j MASQUERADE

$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Acces Web depuis les postes de travail vers le proxy
$IPTABLES -A FORWARD -p TCP -i $IFACE_PDT -o $IFACE_DMZOUT -d $IP_DMZOUT_PROXY --dport 8080 -j ACCEPT -j LOG --log-prefix "Surf Web: "


#puis Proxy vers Internet
$IPTABLES -A FORWARD -p TCP -i $IFACE_VLAN_PDT_ADMIN -o $IFACE_INTERNET -s $192.168.30.5 -m multiport --dport 80,443 -j ACCEPT -j LOG --log-prefix "Surf Web: "
