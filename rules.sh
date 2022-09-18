#!/bin/bash


iface_lo="lo"


iface_inet="ens3"


#Variable serveur web (DMZ)
iface_fw_dmz="v10"
ip_web_srv="10.0.10.2"

#Variable vlan admin 
iface_fw_admin="v30"
ip_win_srv="10.0.30.2"
ip_syslog_srv="10.0.30.3"
ip_siem_srv="10.0.30.4"


iface_fw_work="v100"
ip_work="10.100.0.2"

ip_switch="10.0.30.100"



# Initialisation de la politique de refus pour la table FILTER
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Reinitialisation de la table NAT et FILTER
iptables -t nat -F
iptables -t nat -X
iptables -F
iptables -X

# Autorisation du traffic pour l'interface local
iptables -A INPUT -i $iface_lo -j ACCEPT
iptables -A OUTPUT -o $iface_lo -j ACCEPT


iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

#Conserver uniquement les connexions établies
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT


# Autorisation des requetes DNS transitant entre :
# serveur Active Directory et l'interface Internet
iptables -A FORWARD -p UDP -i $iface_inet -d $ip_win_srv --sport 53 -j ACCEPT
iptables -A FORWARD -p UDP -s $ip_win_srv -o $iface_inet  --dport 53 -j ACCEPT
iptables -A FORWARD -p TCP -i $iface_inet -d $ip_win_srv --sport 53 -j ACCEPT
iptables -A FORWARD -p TCP -s $ip_win_srv -o $iface_inet --dport 53 -j ACCEPT

#WINSERVER - CLIENT01 ( ADDS)
iptables -A FORWARD -p TCP -i $iface_fw_work -o $iface_fw_admin -d $ip_win_srv -m multiport --dport 53,88,135,139,389,445,464,636,3268,3269,4000,4001 -j ACCEPT
iptables -A FORWARD -p TCP -i $iface_fw_work -o $iface_fw_admin -d $ip_win_srv -m multiport --sport 53,88,135,139,389,445,464,636,3268,3269,3389,4000,4001 -j ACCEPT
iptables -A FORWARD -p UDP -i $iface_fw_work -o $iface_fw_admin -d $ip_win_srv -m multiport --dport 53,88,123,135,137,138,389,445,464,3389,4000,4001 -j ACCEPT
iptables -A FORWARD -p UDP -i $iface_fw_work -o $iface_fw_admin -d $ip_win_srv -m multiport --sport 53,88,123,135,137,138,389,445,464,3389,4000,4001 -j ACCEPT

#INTERNET CLIENT01
iptables -A FORWARD -p TCP -i $iface_fw_work -o $iface_inet -m multiport --dport 80,443 -j ACCEPT

#CLIENT01 - WINSERVER (WINRM)
iptables -A FORWARD -p TCP -i $iface_fw_admin  -o $iface_fw_work  -d $ip_work -m multiport --dport 5985,5986 -j ACCEPT

#WEBSERVER - RSYSLOG
iptables -A FORWARD -p TCP -i $iface_fw_dmz  -o $iface_fw_admin  -d $ip_syslog_srv  --dport 514 -j ACCEPT


iptables -A FORWARD -p UDP -s $ip_switch -d $ip_syslog_srv --dport 515 -j ACCEPT


# LOGSERVER - GRAYLOG
iptables -A FORWARD -p TCP -s $ip_syslog_srv -d $ip_siem_srv  --dport 10001 -j ACCEPT
iptables -A FORWARD -p UDP -s $ip_syslog_srv -d $ip_siem_srv  --dport 10003 -j ACCEPT

#WINSERVER - GRAYLOG
iptables -A FORWARD -p UDP -s $ip_win_srv -d $ip_siem_srv --dport 10002 -j ACCEPT








