#Mikrotik script to backup RouterOS to email address
#Email contans key info on the router
#Backups are attached to the email, as well as system log
#Set email address here:
:local eAddress "email@domain.com";
#You need to configure /tool e-mail
:local rName ([/system identity get name]);
:local vDate ([:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6])
:delay 2;
#Actual backup to files on the router
/system backup save name=($rName . "-" . $vDate);
/export terse hide-sensitive file=($rName . "-" . $vDate);
:local sFile1 ($rName . "-" . $vDate . ".backup");
:local sFile2 ($rName . "-" . $vDate . ".rsc");
#List of files to attach to the email
:local aFiles {$sFile1;$sFile2};
:delay 3;
:local sNewLine ("\r\n");
:log info ("$rName" . " Mikrotik backup " . $vDate . " " . [/system clock get time] . " START");
:local voltage [/system health get voltage];
:set $voltage ([:pick $voltage 0 2] . "." . [:pick $voltage 2 3]);
#Email body containing info on the router
:local strBody ($rName  . " Backup " . $vDate . " " . [/system clock get time] );
:set $strBody ($strBody . $sNewLine . "Temp: $[/system health get temperature]C pow: " . voltage ."V");
/system package update check-for-updates once
:delay 3;
:set $strBody ($strBody . $sNewLine . "OS-ver: " . [:system package update get installed-version] . \
	" - " . [:system package update get status]);
:if ([:system package update get status] = "New version is available") do={
	:set $strBody ($strBody . " - UPDATE: " . [system package update get latest-version]);}
:local aSysInfo ([/system routerboard print as-value]);
:set $strBody ($strBody . $sNewLine . $sNewLine . "Model: " . ($aSysInfo->"model") . " ser: " . ($aSysInfo->"serial-number") . " fware: " . ($aSysInfo->"firmware-type") . " v" . ($aSysInfo->"current-firmware"));
:if (($aSysInfo->"current-firmware") != ($aSysInfo->"upgrade-firmware")) do={
	:set $strBody ($strBody . $sNewLine . "UPDATE available: " . ($aSysInfo->"upgrade-firmware"));}
:set aSysInfo ([/system resource print as-value]);
:set $strBody ($strBody . $sNewLine . $sNewLine . "Board: " . ($aSysInfo->"board-name") . ", Platform:" . ($aSysInfo->"platform") . ", Architecture: " . ($aSysInfo->"architecture-name"));
:set $strBody ($strBody . $sNewLine . "CPU: " . ($aSysInfo->"cpu") . " @" . ($aSysInfo->"cpu-count") . "cpu x " . ($aSysInfo->"cpu-frequency") . "Mhz");
:set $strBody ($strBody . $sNewLine . "Uptime: " . ($aSysInfo->"uptime") . ", CPU Load: " . ($aSysInfo->"cpu-load") . "%, Memory: " . (($aSysInfo->"free-memory")/1048576) . "/" . (($aSysInfo->"total-memory")/1048576) . "MB ");
:local curLines ([/system logging print count-only]);
:local totLines ([/system logging action get memory memory-lines]);
:set $strBody ($strBody . $sNewLine . "SysLog: " . $curLines . "/" . $totLines . "lines");
:set $strBody ($strBody . $sNewLine . "HDD: " . (($aSysInfo->"free-hdd-space")/1048576) . "/" . (($aSysInfo->"total-hdd-space")/1048576) . "MB, Write: " . (($aSysInfo->"write-sect-total")/1024) . "K, Bad: " . ($aSysInfo->"bad-blocks") . "%");
:set $strBody ($strBody . $sNewLine . "Ver: " . ($aSysInfo->"version") . ", Build: " . ($aSysInfo->"build-time"));
:set aSysInfo ([/system license print as-value]);
:set $strBody ($strBody . $sNewLine . "Licence: " . ($aSysInfo->"nlevel") . ", id: " . ($aSysInfo->"software-id") . ", Features: " . ($aSysInfo->"features"));
:set $strBody ($strBody . $sNewLine . $sNewLine . "User accounts: " . [user print count-only as-value]);
:foreach int in=[/user find disabled=no] do={
	:set $strBody ($strBody . $sNewLine . "$[/user get $int name] ($[/user get $int group]) last: $[:tostr ([/user get $int last-logged-in])]"); };
:local sWANinterface "";
:local gatewayStatus [:tostr [/ip route get [:pick [find dst-address=0.0.0.0/0 active=yes] 0] gateway-status]];
:local sINTf [:find $gatewayStatus " reachable via" -1];
:if ($sINTf > 1) do={:set $sWANinterface [:pick $gatewayStatus ($sINTf +  16) 255]};
:local scurrentWANIP;
:do {:set $scurrentWANIP ([/ip address get [find interface=$sWANinterface] address])} on-error={:log info "WAN interface find failed"};
:set $strBody ($strBody . $sNewLine . $sNewLine . "WAN interface: " . [:tostr $sWANinterface] . ", IP: " . $scurrentWANIP);
:set $strBody ($strBody . "; Public IP: " . ([/ip cloud get public-address]));
:set $strBody ($strBody . $sNewLine . "DDNS: $[/ip cloud get ddns-enabled]: $[/ip cloud get dns-name]   ");
:set $strBody ($strBody . $sNewLine . "IP Firewalls: RAWs: $[/ip firewall raw print count-only as-value where disabled=no], FILTERs: $[/ip firewall filter print count-only as-value where disabled=no], NATs: $[/ip firewall nat print count-only as-value where disabled=no], MANGLEs: $[/ip firewall mangle print count-only as-value where disabled=no], ALISTs: $[/ip firewall address-list print count-only as-value], LAYER7s: $[/ip firewall layer7-protocol print count-only as-value where disabled=no]")
:set $strBody ($strBody . $sNewLine . $sNewLine . "Interfaces: ");
:foreach int in=[/interface find disabled=no] do={
    :set $strBody ($strBody . $sNewLine . "$[/interface get $int name] ($[/interface get $int type]), Run: $[/interface get $int running] " );
	:local detectID ([/interface detect-internet state find name=[/interface get $int name]]);
	:if (($detectID != []) or ($detectID != "")) do={
		:set $strBody ($strBody . "($[/interface detect-internet state get $detectID state])");
	 };
	:if ([/interface get $int dynamic] != []) do={:set $strBody ($strBody . "(dynamic=$[/interface get $int dynamic]), ")};
   	:set $strBody ($strBody . ", MAC: $[/interface get $int mac-address], Downs: $[/interface get $int link-downs]   "); };
:set $strBody ($strBody . $sNewLine . $sNewLine . "Switch ports: ");
:do {
	:foreach int in=[/interface ethernet switch port find] do={
	:set $strBody ($strBody . $sNewLine . "$[/interface ethernet switch port get $int switch]/$[/interface ethernet switch port get $int name], VLAN: $[/interface ethernet switch port get $int default-vlan-id]");
};	} on-error={:log info "Interface SWITCH ports find failed"};
:set $strBody ($strBody . $sNewLine . $sNewLine . "IP addresses: ");
:foreach int in=[/ip address find disabled=no] do={
	:set $strBody ($strBody . $sNewLine . "$[/ip address get $int address] - Iface: $[/ip address get $int interface] - Net: $[/ip address get $int network]"); };
:set $strBody ($strBody . $sNewLine . $sNewLine . "IP Services: ");
:foreach int in=[/ip service find disabled=no] do={
	:set $strBody ($strBody . $sNewLine . "$[/ip service get $int name], Port: $[/ip service get $int port], IP: $[/ip service get $int address]"); };
:set $strBody ($strBody . $sNewLine . $sNewLine . "IP Routes: ");
:foreach int in=[/ip route find disabled=no] do={
    :set $strBody ($strBody . $sNewLine . "$[/ip route get $int dst-address] - $[/ip route get $int gateway-status]"); };
:set $strBody ($strBody . $sNewLine . $sNewLine . "Neighbors: ");
:do {
	:foreach int in=[/ip neighbor find] do={
	:set $strBody ($strBody . $sNewLine . "$[/ip neighbor get $int identity] ($[/ip neighbor get $int address])");    
};	} on-error={:log info "IP Neighbor find failed"};
:local strAdd "";
:do {
	:foreach int in=[/interface wireless find disabled=no] do={
	:set $strAdd ($strAdd . $sNewLine . [/interface wireless get $int name] . ", SSID: $[/interface wireless get $int ssid], Freq: $[/interface wireless get $int frequency]");
};	} on-error={:log info "Interface WIRELESS find failed"};
:do {
	foreach int in=[/interface w60g find disabled=no] do={
	:set $strAdd ($strAdd . $sNewLine . [/interface w60g get $int name] . ", SSID: $[/interface w60g get $int ssid], Freq: $[/interface w60g get $int frequency]");
};	}  on-error={:log info "Interface W60G find failed"};
:do {
	:foreach int in=[/interface lte find disabled=no] do={
	:set $strAdd ($strAdd . $sNewLine . [/interface lte get $int name] . ", Net-mode: $[/interface lte get $int network-mode], APN: $[/interface lte get $int apn-profiles]");
};	} on-error={:log info "Interface LTE find failed"};
if ($strAdd!="") do={:set $strBody ($strBody . $sNewLine . $sNewLine . "Wireless: " . $strAdd)};
:set strAdd ("");
:do {
	:foreach int in=[/ppp active find] do={
	:set $strAdd ($strAdd . $sNewLine . "User: $[/ppp active get $int name], Svc: $[/ppp active get $int service], Cid: $[/ppp active get $int caller-id], IP: $[/ppp active get $int address]");
};	} on-error={:log info "PPP Active Users find failed"};
if ($strAdd!="") do={:set $strBody ($strBody . $sNewLine . $sNewLine . "PPP active users: " . $strAdd)};
#Copy log content into files to be attached
:local nLogFile 1;:local logFile;
:local sLogContent;:local sLogLine;
:local lLogContent 0;:local lLogLine;
:foreach int in=[/log find ] do={
	:set $sLogLine ([:tostr [/log get $int time]] . " - " . [:tostr [/log get $int topics]] . ": " . [:tostr [/log get $int message]]);
	:set $lLogLine ([:len ($sLogLine)]);
#Mirkotik string variable is limited to 4096 bytes, so log file has to be segmented
	if (($lLogContent + 3 + $lLogLine) > 4000) do={
		:set $logFile ($rName . "_log_" . $nLogFile);
		/file print file=$logFile;:set $logFile ($logFile . ".txt");
		:delay 5;
		/file set [/file find name=$logFile] contents=($sLogContent);
		:set $aFiles ($aFiles, $logFile);:set $nLogFile ($nLogFile + 1);:set $sLogContent "";:set $lLogContent 0;
	};
	:set $sLogContent ($sLogContent . $sNewLine . $sLogLine);
	:set $lLogContent ($lLogContent + 4 + $lLogLine); };
#Truncate the log    
/system logging action set memory memory-lines 1;
/system logging action set memory memory-lines $totLines;
:set $logFile ($rName . "_log_" . $nLogFile);
/file print file=$logFile;
:set $logFile ($logFile . ".txt");
:delay 5;
/file set [/file find name=$logFile] contents=($sLogContent);
:set $aFiles ($aFiles, $logFile);
:log info ("$rName" . " Mikrotik backup " . $vDate . " $[/system clock get time]" . \
    " Len (body): $[:len $strBody]" . \
	" Temperature: $[/system health get temperature]C power: " . voltage ."V" . \
	" SysLog memory lines: " . $curLines . "/" . $totLines . \
	" User accounts: " . [user print count-only as-value] . \
	" Attachments: $[:tostr ($aFiles)]"	);    
:delay 5;
/tool e-mail send to=$eAddress subject=($rName . " Mikrotik Backup " . $vDate . [/system clock get time]) file=$aFiles body=$strBody;
:delay 10;
#Delete all temporary files
:foreach sFile in=$aFiles do={/file remove [/file find name=$sFile];};