#Danko firewall rules
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip ssh set strong-crypto=yes
/system ntp client set enabled=yes server-dns-names=europe.pool.ntp.org
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
/system logging action set 0 memory-lines=500
#
/interface list add name=WAN
/interface list add name=LAN
/interface detect-internet set detect-interface-list=all internet-interface-list=all lan-interface-list=static wan-interface-list=all
/ip cloud set ddns-enabled=yes
#
#User addresses assigned by DHCP server
#192.168.0.0/16 - Local LAN IP block
#192.168.0.0/17 - User range (local IP open)
#192.168.0.128/17 - Guest range (no local access)
#192.168.11.0/24 - Local LAN, staticly assigned by DHCP (default gateway)
#192.168.11.1 - router LAN IP (default gateway)
#192.168.89.11-250 - VPN IP pool
#192.168.11.100-250 - LAN DHCP dynamic pool for local equipment
#192.168.201.100-250 - LAN DHCP dynamic pool for known guests
#192.168.202.11-250 - LAN DHCP dynamic pool for unknown guests
#192.168.222.11-250 - LAN DHCP dynamic pool for blocked guests

/ip firewall connection tracking set enabled=yes loose-tcp-tracking=no
/ip neighbor discovery-settings set discover-interface-list=LAN
#
/ip firewall filter add action=accept chain=input comment="input established,related,untracked" connection-state=established,related,untracked
/ip firewall filter add action=drop chain=input comment="drop invalid input" connection-state=invalid log-prefix="drop invalid input"
/ip firewall filter add action=drop chain=input comment="drop input ICMP PING from WAN" icmp-options=8:0 in-interface-list=WAN log-prefix="drop input ICMP" protocol=icmp
/ip firewall filter add action=drop chain=input comment="drop input guest dhcp pool" log-prefix="drop input guest dhcp" src-address=192.168.128.0/17
/ip firewall filter add action=add-src-to-address-list address-list=knock address-list-timeout=1m chain=input comment="knock port tcp" dst-port=00000 in-interface-list=WAN log=yes log-prefix=knock-add protocol=tcp
/ip firewall filter add action=add-src-to-address-list address-list=block address-list-timeout=10m chain=input comment="add to WAN block list" in-interface-list=WAN log-prefix=block-add protocol=tcp src-address-list=!knock
/ip firewall filter add action=drop chain=input comment="drop input block-ed" log-prefix=drop-block src-address-list=block
/ip firewall filter add action=accept chain=input comment="accept knock-ed ssh,winbox,sstp" dst-port=22,8291,44366 log=yes log-prefix=knock-in protocol=tcp src-address-list=knock src-port=""
/ip firewall filter add action=drop chain=input comment="drop input not from LAN" in-interface-list=!LAN log-prefix="drop external"
/ip firewall filter add action=accept chain=input comment="TEST - count accept input"
/ip firewall filter add action=fasttrack-connection chain=forward comment="fasttrack connected" connection-state=established,related
/ip firewall filter add action=drop chain=forward comment="drop external with local address" in-interface-list=WAN log=yes log-prefix="drop ext local ip" src-address=192.168.0.0/16
/ip firewall filter add action=drop chain=forward comment="drop dhcp guest-home" dst-address=192.168.0.0/17 log-prefix="drop dhcp guest-home" src-address=192.168.128.0/17
/ip firewall filter add action=drop chain=forward comment="drop dhcp home-guest" dst-address=192.168.128.0/17 log-prefix="drop dhcp home-guest" src-address=192.168.0.0/17
/ip firewall filter add action=drop chain=forward comment="drop invalid forward" connection-state=invalid log-prefix="drop invalid forward"
/ip firewall filter add action=drop chain=forward comment="drop all from WAN not DSTNATed" connection-nat-state=!dstnat connection-state=new in-interface-list=WAN log-prefix="Drop not DSTNAT"
/ip firewall filter add action=drop chain=forward comment="drop bloked IP pool" log=yes log-prefix="drop blocked" src-address=129.168.222.0/24
/ip firewall filter add action=accept chain=forward comment="accept established,related, untracked" connection-state=established,related,untracked
/ip firewall filter add action=accept chain=forward comment="TEST - count accept forward"
/ip firewall filter add action=drop chain=output comment="drop out ICMP redirect (for local-proxy-arp)" icmp-options=5:0-255 log=yes log-prefix="drop out ICMP redirect" out-interface-list=LAN protocol=icmp
/ip firewall nat add action=masquerade chain=srcnat comment="standard NAT" out-interface-list=WAN
/ip firewall nat add action=masquerade chain=srcnat comment="NAT for VPN traffic" log-prefix=NAT-vpn src-address=192.168.89.0/24
/ip firewall nat add action=masquerade chain=srcnat comment="NAT for IP camera building network" dst-address=192.168.100.0/24 log-prefix=IPcam-net out-interface=ether000 src-address=192.168.0.0/16
/ip firewall nat add action=dst-nat chain=dstnat comment="IP internal camera pubic access" dst-address=!254.255.255.255 dst-port=00000 log-prefix=IPcam-portmap protocol=tcp to-addresses=192.168.11.00 to-ports=37777
/ip firewall nat add action=masquerade chain=srcnat comment="hairpin for internal IP camera" dst-address=192.168.11.00 dst-port=37777 log-prefix=IPcam-hairpin out-interface-list=LAN protocol=tcp src-address=192.168.0.0/16 src-port=""
/ip firewall nat add action=dst-nat chain=dstnat comment="port open za Torrent" dst-address=!254.255.255.255 dst-port=00000 log-prefix=torrent protocol=tcp to-addresses=192.168.11.00
/ip firewall nat add action=dst-nat chain=dstnat comment="SFTP for cloud server backup" dst-port=00000 log-prefix=SFTP-NAS protocol=tcp src-address=0.0.0.0 to-addresses=192.168.11.00 to-ports=22