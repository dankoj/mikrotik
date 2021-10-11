#Check_Status script - schedule to run every 10 minutes
#Check variables and if any significant change send Telegram message
:global sendmessage;
:local tempstatus;
:local systemtemp [/system health get temperature];
:if (systemtemp > "43") do={:set $tempstatus "system temp is elevated"};
:if (systemtemp > "50") do={:set $tempstatus "system temp is too high"};
:if (systemtemp > "60") do={:set $tempstatus "system temp is critical"};
:if (systemtemp < "44") do={:set $tempstatus "system temp is within spec"};
:global templaststatus;
:if ($"tempstatus" != $"templaststatus") do {
	$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] " . $tempstatus . ": " . $systemtemp . "C");
	:set $templaststatus $tempstatus; }
:global aIfaceS;
:local LaIfaceS;
:set $LaIfaceS ( [/interface print as-value where running=yes]);
:if ([:tostr $LaIfaceS] != [:tostr $aIfaceS]) do={
    :local Itxt;
    :foreach i in=$LaIfaceS do={
	    :set $Itxt ($Itxt . ($i -> "name") .  "(" . ($i -> "comment") . "), ");
    }    
	$sendmessage ("Running interface changed: " . $Itxt);
	:log info ("Iface: " . [:tostr $LaIfaceS]);    
	:set $aIfaceS ($LaIfaceS);
}
#Change in number of users can signal that the router has been hacked   
:local nUsers ([user print count-only as-value]);
:global nLastUsers;
:if ($nUsers != $nLastUsers) do {
	$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] User accounts changed from: " . $nLastUsers . " to: " . $nUsers . "!");
	:set $nLastUsers $nUsers; }
#Signal any change in public IP address or connectivity       
:local newIP;
:global WANinterface; 
:global currentWANIP;
if ($WANinterface != "") do={
    :set $newIP ([/ip address get [find interface=$WANinterface] address]);
	:if ($newIP != $currentWANIP) do={
		$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] WAN IP address changed from: " . $currentWANIP . " to: " . $newIP . " on interface: " . $WANinterface);
		:set $currentWANIP $newIP; } }
:set $newIP ([ip cloud get public-address]);
:global currentIP;
:if ($newIP != $currentIP) do={
	$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] Public IP address changed from: " . $currentIP . " to: " . $newIP . " !");
	:set $currentIP $newIP; }
:local aIntInterface;
:set $aIntInterface ([/interface detect-internet state print as-value where state="internet"]);
:local sIntInterfaceNew "";
:foreach i in=$aIntInterface do={:set $sIntInterfaceNew ($sIntInterfaceNew . ($i->"name") . ";") }
:global sIntInterface;
:if ($sIntInterfaceNew != $sIntInterface) do={
	$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] Internet interfaces changed from: " . $sIntInterface . " to: " . $sIntInterfaceNew . "!");
	:set $sIntInterface $sIntInterfaceNew; }
#Change in number of firewall rules can signal that the router has been hacked       
:local newFirewalls ("RAWs: $[/ip firewall raw print count-only as-value where disabled=no], FILTERs: $[/ip firewall filter print count-only as-value where disabled=no], NATs: $[/ip firewall nat print count-only as-value where disabled=no], MANGLEs: $[/ip firewall mangle print count-only as-value where disabled=no], LAYER7s: $[/ip firewall layer7-protocol print count-only as-value where disabled=no]");
:global sFirewalls;
:if ($newFirewalls != $sFirewalls) do={
	$sendmessage ("Router $[/system identity get name] $[/system clock get date] $[/system clock get time] IP Firewalls from: " . $sFirewalls . " to: " . $newFirewalls . " !");
	:set $sFirewalls $newFirewalls; }    
#call to send old messages from $aMessages
:global aMessages;
if ([:len $aMessages]>0) do={
    :log info ("Re-sending status: " . $aMessages);
    $sendmessage ("");  };
#:log info "Scheduled check done";
