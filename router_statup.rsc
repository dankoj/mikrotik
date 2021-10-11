:delay 10;
:log info "Router Startup script";
#To retain global variable value it has to be defined in startup
:global vDHCParray;:global aMessages;
:global templaststatus "system temp is within spec";
:global nLastUsers ([user print count-only as-value]);
:local textMessage ("Router $[/system identity get name] STARTUP $[/system clock get date] $[/system clock get time]");
:delay 30;
#Parse function to send message to Telegram app
#Declare variables and collect statues so thay can be re-checked with Check_Status script
:global sendmessage [:parse [/system script get send_message source]];
:local voltage [/system health get voltage];:set $voltage ([:pick $voltage 0 2] . "." . [:pick $voltage 2 3]);
:global WANinterface "";
:local gatewayStatus [:tostr [/ip route get [:pick [find dst-address=0.0.0.0/0 active=yes] 0] gateway-status]];
:local i [:find $gatewayStatus " reachable via" -1];
:if ($i > 1) do={:set $WANinterface [:pick $gatewayStatus ($i +  16) 255]};
:global currentWANIP ([/ip address get [find interface=$WANinterface] address]);
:global currentIP ([/ip cloud get public-address]);
:local aIntInterface;set $aIntInterface ([/interface detect-internet state print as-value where state="internet"]);
:global sFirewalls ("RAWs: $[/ip firewall raw print count-only as-value where disabled=no], FILTERs: $[/ip firewall filter print count-only as-value where disabled=no], NATs: $[/ip firewall nat print count-only as-value where disabled=no], MANGLEs: $[/ip firewall mangle print count-only as-value where disabled=no], LAYER7s: $[/ip firewall layer7-protocol print count-only as-value where disabled=no]");
:global aIfaceS;
:set $aIfaceS ( [/interface  print as-value where running=yes]);
:log info ("Running interfaces: " . $aIfaceS);
:global sIntInterface "";
:foreach i in=$aIntInterface do={:set $sIntInterface ($sIntInterface . ($i->"name") . ";") }
:log info ("Default interface: " . $WANinterface . " Internet interfaces: " . $sIntInterface);
:set $textMessage ($textMessage . " User accounts: " . $nLastUsers);
:set $textMessage ($textMessage . " temperature: $[/system health get temperature]C power: " . voltage . "V");
:set $textMessage ($textMessage . "  Firewall: " . $sFirewalls);
:delay 60;
$sendmessage ($textMessage);
:delay 60;
:system script run backup;
#To retain global variable value statup has to continue running indefinitely 
:while (1) do={:delay 60;};
:log info "Router Startup script ENDS";
