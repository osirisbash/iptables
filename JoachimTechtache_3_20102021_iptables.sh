#!/bin/bash

#Variable chemin IPtables
IPTABLES="/usr/sbin/iptables"

#Variables interface local
iface_lo="lo"

#Variable Internet
iface_inet="ens3"
ip_inet="192.168.30.1"

#Variable serveur web (DMZ)
iface_webserver="ens4"
ip_webserver="192.168.40.2"

#Variable VLAN du poste de travail (VLAN10)
iface_fw_work="ens5.10"

#Variable VLAN du poste administration (VLAN20)
iface_fw_admin="ens5.20"
ip_admin="192.168.52.2"

#Variable VLAN du serveur Active Directory (VLAN30)
iface_fw_winserver="ens5.30"
ip_winserver="192.168.53.2"


# Initialisation de la politique de refus pour la table FILTER
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -P FORWARD DROP

#Reinitialisation de la table NAT et FILTER
$IPTABLES -t nat -F
$IPTABLES -t nat -X
$IPTABLES -F
$IPTABLES -X

# Autorisation du traffic pour l'interface local
$IPTABLES -A INPUT -i $iface_lo -j ACCEPT
$IPTABLES -A OUTPUT -o $iface_lo -j ACCEPT


#Traduction des paquets sortants du réseau local vers l'IP source de connexion Internet
$IPTABLES -t nat -A POSTROUTING -o $iface_inet -j SNAT --to-source $ip_inet

#Conserver uniquement les connexions établies
$IPTABLES -A FORWARD -m state --state ESTABLISHED -j ACCEPT

# Autorisation des requetes DNS transitant entre :
# serveur Active Directory et l'interface Internet
$IPTABLES -A FORWARD -p UDP -i $iface_inet -d $ip_winserver --sport 53 -j ACCEPT
$IPTABLES -A FORWARD -p UDP -s $ip_winserver -o $iface_inet  --dport 53 -j ACCEPT
$IPTABLES -A FORWARD -p TCP -i $iface_inet -d $ip_winserver --sport 53 -j ACCEPT
$IPTABLES -A FORWARD -p TCP -s $ip_winserver -o $iface_inet --dport 53 -j ACCEPT


# Autorisation des requetes transitant entre : 
# le VLAN du poste de travail (VLAN10) et le serveur Active Directory (VLAN30)
$IPTABLES -A FORWARD -p TCP -i $iface_fw_work -o $iface_fw_winserver -d $ip_winserver -m multiport --dport 53,88,135,139,389,445,464,636,3268,3269,4000 -j ACCEPT
$IPTABLES -A FORWARD -p UDP -i $iface_fw_work -o $iface_fw_winserver -d $ip_winserver -m multiport --dport 53,88,123,135,137,138,389,445,464,4000,4001 -j ACCEPT



# Autorisation des requetes transitant entre : 
# le VLAN du poste administration (VLAN20) et le serveur Active Directory (VLAN30)
$IPTABLES -A FORWARD -p TCP -i $iface_fw_admin -o $iface_fw_winserver -d $ip_winserver -m multiport --dport 53,88,135,139,389,445,464,636,3268,3269,4000 -j ACCEPT
$IPTABLES -A FORWARD -p UDP -i $iface_fw_admin -o $iface_fw_winserver -d $ip_winserver -m multiport --dport 53,88,123,135,137,138,389,445,464,4000 -j ACCEPT


#53 : DNS
#88 : Kerberos
#123 : Windows Time
#135 : RPC, EPM
#137 : NetLogon, NetBIOS Name Resolution
#138 : DFSN, NetLogon, NetBIOS Datagram Service
#139 :  DFSN, NetBIOS Session Service, NetLogon
#389 : LDAP
#445 : SMB,CIFS,SMB2, DFSN, LSARPC, NbtSS, NetLogonR, SamR, SrvSvc
#464 : Kerberos change/set password
#636 : LDAP SSL
#3268 : LDAP GC
#3269 : LDAP GC SSL
#4000 : RPC, DCOM, EPM, DRSUAPI, NetLogonR, SamR, FRS



# Autorisation des requetes HTTP,HTTPS transitant entre :
# le serveur web et le VLAN du poste de travail (VLAN10)
$IPTABLES -A FORWARD -p TCP -i $iface_fw_work -o $iface_webserver -d $ip_webserver -m multiport --dport 80,443 -j ACCEPT

# Autorisation des requetes HTTP,HTTPS transitant entre :
# le serveur web et le VLAN du poste administration (VLAN20)
$IPTABLES -A FORWARD -p TCP -i $iface_fw_admin -o $iface_webserver -d $ip_webserver -m multiport --dport 80,443 -j ACCEPT


# Autorisation des requetes HTTP,HTTPS transitant entre :
# le serveur web et l'extérieur du réseau
$IPTABLES -A FORWARD -p TCP -i $iface_inet -o $iface_webserver -d $ip_webserver -m multiport --dport 80,443 -j ACCEPT


# Autorisation des requetes HTTP,HTTPS transitant entre : 
# le VLAN du poste de travail (VLAN10) et l'interface Internet
$IPTABLES -A FORWARD -p TCP -i $iface_fw_work -o $iface_inet -m multiport --dport 80,443 -j ACCEPT

# Autorisation des requetes HTTP,HTTPS transitant entre : 
# le VLAN du poste administration (VLAN20) et l'interface Internet
$IPTABLES -A FORWARD -p TCP -i $iface_fw_admin -o $iface_inet -m multiport --dport 80,443 -j ACCEPT


# Autorisation des requetes SSH transitant entre : 
# le poste administration (VLAN20) et le pare-feu
$IPTABLES -A FORWARD -p TCP -i $ip_admin -d $iface_fw_admin --dport 22 -j ACCEPT


# Autorisation des requetes SSH transitant entre : 
# le poste administration (VLAN20) et le serveur web
$IPTABLES -A FORWARD -p TCP -s $ip_admin -o $iface_webserver -d $ip_webserver --dport 22 -j ACCEPT

# Autorisation des requetes RDP transitant entre : 
# le poste administration (VLAN20) et le serveur Active Directory
$IPTABLES -A FORWARD -p TCP -s $ip_admin -o $iface_fw_winserver -d $ip_winserver --dport 3389  -j ACCEPT


# Fin du fichier
