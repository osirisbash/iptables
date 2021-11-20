#!/bin/sh

# fichier de configuration IPtables
# cree depuis http://www.canonne.net
# (c) 2003 Antoine CANONNE

# Nous vidons toutes les chaines
iptables -F

# Nous supprimons les chaines non standards
iptables -X

# Par defaut tout est ferme
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# reinitialisation table NAT
iptables -t nat -F
iptables -t nat -X

iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT

# Translation d'adresse pour tout ce qui sort vers l'internet
iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE

# La machine locale est sure
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Resolution DNS pour le firewall
iptables -A INPUT  -i ens4 --protocol udp --source-port 53 -j ACCEPT
iptables -A OUTPUT -o ens4 --protocol udp --destination-port 53 -j ACCEPT
iptables -A INPUT  -i ens4 --protocol tcp --source-port 53 -j ACCEPT
iptables -A OUTPUT -o ens4 --protocol tcp --destination-port 53 -j ACCEPT 

# Resolution DNS pour les machines du LAN
iptables -A FORWARD -i ens4 -o ens6.30 --protocol udp --source-port 53 -j ACCEPT
iptables -A FORWARD -i ens6.30 -o ens4 --protocol udp --destination-port 53 -j ACCEPT
iptables -A FORWARD -i ens4 -o ens6.30 --protocol tcp --source-port 53 -j ACCEPT
iptables -A FORWARD -i ens6.30 -o ens4 --protocol tcp --destination-port 53 -j ACCEPT 

# connexions Firewall-Internet (www)
iptables -A OUTPUT -p tcp --dport 80  -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT  -p tcp --sport 80  -i ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT  -p tcp --sport 443 -i ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT

# connexions LAN-Internet (www)
iptables -A FORWARD -p tcp --dport 80  -i ens6.30 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -i ens6.30 -o ens4 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp --sport 80  -i ens4 -o ens6.30 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -i ens4 -o ens6.30 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Fin du fichier

