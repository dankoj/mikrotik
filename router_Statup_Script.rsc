:global sendmessage;
:global nLastUsers;
:global currentIP;
:global currentWANIP;
:global WANinterface;
:global sFirewalls;
:global aIfaceS;
:global primGateway;
#Startup logic moved to Startup_Script (Changes in 2023 for compatibility with RouterOS 7.x)
#:log info ("Startup_Script starting");
:local textMessage ("Router $[/system identity get name] STARTUP $[/system clock get date] $[/system clock get time]");
:set nLastUsers ([user print count-only as-value]);
:local voltage [:tostr [/system health get [find name="voltage"] value]];
:local gatewayStatus [:tostr [/ip route get [:pick [find dst-address=0.0.0.0/0 active=yes] 0] immediate-gw]];
#:log info ($gatewayStatus);
:local i [:find $gatewayStatus "%" -1];
:if ($i > 1) do={:set $WANinterface [:pick $gatewayStatus ($i +  1) 255]};
#:log info ($WANinterface);
:set currentWANIP ([/ip address get [find interface=$WANinterface] address]);
#:log info ("currentWANIP " . $currentWANIP);
:set currentIP ([/ip cloud get public-address]);
:local aIntInterface;
#:set $aIntInterface ([/interface detect-internet state print as-value where state="internet"]);
set $aIntInterface ([/interface detect-internet state print as-value]);
:log info ("aIntInterface " . $aIntInterface);
:set sFirewalls ("RAWs: $[/ip firewall raw print count-only as-value where disabled=no], FILTERs: $[/ip firewall filter print count-only as-value where disabled=no], NATs: $[/ip firewall nat print count-only as-value where disabled=no], MANGLEs: $[/ip firewall mangle print count-only as-value where disabled=no], LAYER7s: $[/ip firewall layer7-protocol print count-only as-value where disabled=no]");
:set $aIfaceS ( [/interface  print as-value where running=yes]);
:log info ("Running interfaces: " . $aIfaceS);
:foreach i in=$aIntInterface do={:set $sIntInterface ($sIntInterface . ($i->"name") . ";") }
#:log info ("Default interface: " . $WANinterface . " Internet interfaces: " . $sIntInterface);
:set $textMessage ($textMessage . " User accounts: " . $nLastUsers);
:set $textMessage ($textMessage . " temperature: $[/system health get [find name="temperature"] value]C power: " . voltage . "V");
:set $textMessage ($textMessage . "  Firewall: " . $sFirewalls);
#:log info ($textMessage);
$sendmessage ($textMessage);
