#DHCP_alert - script to signal if any additional DHCP server on the network
:global sendmessage;
:local txtAlert;:local rMacAdd;
:set $txtAlert ("Router $[ /system identity get name] DHCP server ALERT $[/system clock get date] $[/system clock get time]");
foreach int in=[/ip dhcp-server alert find] do={
    set $rMacAdd ([/ip dhcp-server alert get $int unknown-server]);
    set $txtAlert ($txtAlert . " MAC address: " . $rMacAdd );
    do {
        set $txtAlert ($txtAlert . ", ARP IP address: $[/ip arp get [/ip arp find where mac-address=$rMacAdd] address ]");
    } on-error={set $txtAlert ($txtAlert . " (unknow ARP IP address)") ;};
#    set $txtAlert ($txtAlert . " SWITCH Port: $[/interface ethernet switch host get [/interface ethernet switch host find where mac-address=$rMacAdd] ports ]");
}
#:log info $txtAlert;
$sendmessage $txtAlert;
