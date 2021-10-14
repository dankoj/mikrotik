#Danko firewall rules
#all port numbers obfuscated to 1,2,3...
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip ssh set strong-crypto=yes
/system ntp client set enabled=yes server-dns-names=europe.pool.ntp.org
/tool bandwidth-server set enabled=no
/tool mac-server set allowed-interface-list=none
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
#192.168.YY.0/24 - Local LAN, staticly assigned by DHCP (default gateway)
#192.168.VV.11-250 - VPN IP pool
#192.168.YY.100-250 - LAN DHCP dynamic pool for local equipment
#192.168.201.100-250 - LAN DHCP dynamic pool for known guests
#192.168.202.11-250 - LAN DHCP dynamic pool for unknown guests
#192.168.222.11-250 - LAN DHCP dynamic pool for blocked guests
#
/ip firewall connection tracking set enabled=yes loose-tcp-tracking=no
/ip neighbor discovery-settings set discover-interface-list=LAN
/interface detect-internet set detect-interface-list=WAN internet-interface-list=WAN lan-interface-list=LAN wan-interface-list=WAN
/ip cloud set ddns-enabled=yes
/ip firewall address-list add address=d99999999999.sn.mynetname.net list=WAN-IP
/ip firewall filter add action=drop chain=input comment="drop input block-ed not from local lan" in-interface=!bridgeLocal log-prefix=drop-block src-address-list=block
/ip firewall filter add action=drop chain=input comment="TCP non SYN scan attack input" connection-state=new protocol=tcp tcp-flags=!syn
/ip firewall filter add action=accept chain=input comment="input established,related,untracked" connection-state=established,related,untracked
/ip firewall filter add action=drop chain=input comment="drop invalid input" connection-state=invalid log-prefix="drop invalid input"
/ip firewall filter add action=drop chain=input comment="drop input ICMP PING from WAN" icmp-options=8:0 in-interface-list=WAN log-prefix="drop input ICMP" protocol=icmp
/ip firewall filter add action=drop chain=input comment="drop input guest dhcp pool" log-prefix="drop input guest dhcp" src-address=192.168.128.0/17
/ip firewall filter add action=add-src-to-address-list address-list=knock-1 address-list-timeout=1m30s chain=input comment="knock1-add port 1?/tcp" dst-port=1111 log=yes log-prefix=knock1-add protocol=tcp src-address-list=!block
/ip firewall filter add action=add-src-to-address-list address-list=knock-2 address-list-timeout=5m chain=input comment="knock2-add port 2?/tcp" dst-port=2222 log=yes log-prefix=knock2-add protocol=tcp src-address-list=knock-1
/ip firewall filter add action=add-src-to-address-list address-list=block address-list-timeout=9m chain=input comment="add to WAN block list" dst-port=!1,2,3 in-interface=!bridgeLocal in-interface-list=WAN log-prefix=block-add protocol=tcp src-address-list=!knock-2
/ip firewall filter add action=accept chain=input comment="Accept input knock-ed WinBox, SSTP" dst-port=4,5 log=yes log-prefix="input WinBox, SSTP" protocol=tcp src-address-list=knock-2
/ip firewall filter add action=drop chain=input comment="drop input not from local LAN" in-interface=!bridgeLocal log-prefix=drop-extern-end
/ip firewall filter add action=accept chain=input comment="TEST - count accept input" disabled=yes log-prefix=test-input
/ip firewall filter add action=drop chain=forward comment="drop forward block-ed not from local lan" in-interface=!bridgeLocal log-prefix="drop forward blocked" src-address-list=block
/ip firewall filter add action=fasttrack-connection chain=forward comment="fasttrack connected" connection-state=established,related
/ip firewall filter add action=drop chain=forward comment="TCP non SYN scan attack forward" connection-state=new protocol=tcp tcp-flags=!syn
/ip firewall filter add action=drop chain=forward comment="drop external with local address" in-interface-list=WAN log-prefix="drop ext local ip" src-address=192.168.0.0/16
/ip firewall filter add action=drop chain=forward comment="drop invalid forward" connection-state=invalid log-prefix="drop invalid forward"
/ip firewall filter add action=drop chain=forward comment="drop dhcp guest-home" dst-address=192.168.0.0/17 log-prefix="drop dhcp guest-home" src-address=192.168.128.0/17
/ip firewall filter add action=drop chain=forward comment="drop dhcp home-guest" dst-address=192.168.128.0/17 log-prefix="drop dhcp home-guest" src-address=192.168.0.0/17
/ip firewall filter add action=drop chain=forward comment="drop all from WAN not DSTNATed" connection-nat-state=!dstnat connection-state=new in-interface-list=WAN log-prefix="Drop not DSTNAT"
/ip firewall filter add action=drop chain=forward comment="drop blocked IP pool" log-prefix=drop-block src-address=129.168.222.0/24
/ip firewall filter add action=accept chain=forward comment="accept established,related, untracked" connection-state=established,related,untracked
/ip firewall filter add action=add-src-to-address-list address-list=knock-2 address-list-timeout=11m chain=forward comment="Extend knock-2 for nonpermanent app" dst-port=6 log=yes log-prefix=knock2-extend protocol=tcp src-address-list=knock-2
/ip firewall filter add action=accept chain=forward comment="Accept forward dnsnat knock-ed ports" connection-nat-state=dstnat dst-port=7,8,9 log=yes log-prefix=forward-accept-ports protocol=tcp src-address-list=knock-2
/ip firewall filter add action=accept chain=forward comment="Torrent port 10 forward" connection-nat-state=dstnat dst-port=10 log-prefix=torrent-forward protocol=tcp
/ip firewall filter add action=accept chain=forward comment="SFTP for sajt backup->nat/22" connection-nat-state=dstnat dst-port=22 log-prefix=sftp-web protocol=tcp src-address=194.146.57.56
/ip firewall filter add action=accept chain=forward comment="TEST - count accept forward" disabled=yes log=yes log-prefix=test-forward
/ip firewall filter add action=drop chain=forward comment="End forward rule - drop all " in-interface-list=WAN log-prefix=drop-forward-end
/ip firewall filter add action=drop chain=output comment="drop out ICMP redirect (local net connection local-proxy-arp)" icmp-options=5:0-255 log-prefix="drop out ICMP redirect" out-interface-list=LAN protocol=icmp
/ip firewall nat add action=masquerade chain=srcnat comment="Standard NAT" out-interface-list=WAN
/ip firewall nat add action=masquerade chain=srcnat comment="NAT for VPN traffic" log=yes log-prefix=NAT-vpn src-address=192.168.VV.0/24
/ip firewall nat add action=masquerade chain=srcnat comment="NAT for building network cameras" dst-address=192.168.100.0/24 log-prefix=NAT-building out-interface=ether5 src-address=192.168.0.0/16
/ip firewall nat add action=masquerade chain=srcnat comment="Management local LAN for Telekom-MTS link" dst-address=192.168.1.0/24 log-prefix=NAT-MTS-mngm out-interface=ether2
/ip firewall nat add action=dst-nat chain=dstnat comment="NAT-port camera from LAN" dst-address=!254.255.255.255 dst-port=15 in-interface-list=LAN log-prefix=NAT-cam-lan protocol=tcp src-address=192.168.0.0/16 to-addresses=192.168.LL.XX to-ports=37777
/ip firewall nat add action=dst-nat chain=dstnat comment="NAT-port camera from outside" dst-address=!254.255.255.255 dst-port=15 in-interface-list=WAN log-prefix=NAT-cam-port protocol=tcp src-address-list=knock-2 to-addresses=192.168.LL.XX to-ports=37777
/ip firewall nat add action=masquerade chain=srcnat comment="NAT-hairpin camera" dst-address=192.168.LL.41 dst-port=37777 log-prefix=NAT-cam-hairpin protocol=tcp src-address=192.168.0.0/16
/ip firewall nat add action=dst-nat chain=dstnat comment="NAT-port home server from LAN" dst-port=16 in-interface-list=LAN log-prefix=NAT-HA-lan protocol=tcp src-address=192.168.0.0/16 to-addresses=192.168.LL.YY to-ports=8123
/ip firewall nat add action=dst-nat chain=dstnat comment="NAT-port home server from outside" dst-port=16 in-interface-list=WAN log=yes log-prefix=NAT-HA-port protocol=tcp src-address-list=knock-2 to-addresses=192.168.LL.YY
/ip firewall nat add action=masquerade chain=srcnat comment="NAT-hairping home server" dst-address=192.168.LL.YY dst-port=16 log-prefix=NAT-HA-hairpin protocol=tcp src-address=192.168.0.0/16
/ip firewall nat add action=dst-nat chain=dstnat comment="Torrent NAT port TCP" dst-address=!254.255.255.255 dst-port=10 in-interface-list=WAN log-prefix=NAT-torrent protocol=tcp to-addresses=192.168.LL.YY
/ip firewall nat add action=dst-nat chain=dstnat comment="SFTP NAT for sajt backup->nat/22" dst-port=44422 in-interface-list=WAN log-prefix=NAT-SFTP-NAS protocol=tcp src-address=194.146.57.56 to-addresses=192.168.LL.55 to-ports=22
