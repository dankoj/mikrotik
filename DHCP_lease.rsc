#DHCP server lease script
#DHCP lease time should be reduced - recommended to 1h (60 minutes)
#Parameter $leaseActMAC is MAC address that has just being leased
#:local vMAC;:set $vMAC ($leaseActMAC);
#:log info ($leaseActMAC);
#array vDHCParray has to be set as global in startup script - otherwise it looses value
:global vDHCParray; :global sendmessage;
#Find this entry in the table, get the sub-array, and then properties
:local vTxt; :set $vTxt ([/ip dhcp-server lease print as value where mac-address=$leaseActMAC]);
:set $vTxt ([:pick $vTxt 0]);
:local vStatus; :set $vStatus ($vTxt -> "status");
#:local vAddress; :set $vAddress ($vTxt -> "address");
:local vComment; :set $vComment ($vTxt -> "comment");
#if host-name is undefined use MAC address
:local vTxtStr; :local vHost;
:if ((([:typeof ($vTxt -> "host-name")])="nothing") or (($vTxt -> "host-name")="")) do={:set $vHost $leaseActMAC} else={:set $vHost ($vTxt -> "host-name")};
#:log info ($vHost . "=" . $leaseActIP . ": " . $vComment);
#If the first character of the Comment (static assignement only) is "-" then do not send the message
:if (($leaseBound=1) and ($vStatus="bound") and ([:pick $vComment 0]!="-")) do={
	:local mydate1 [/system clock get date];:local mytime1 [/system clock get time];:local myUTCoff [/system clock get gmt-offset];
	:local date1month [:pick $mydate1 0 3];:local date1day [:pick $mydate1 4 6];:local date1year [:pick $mydate1 7 11];
	:local date1hours [:pick $mytime1 0 2];:local date1minutes [:pick $mytime1 3 5];:local date1seconds [:pick $mytime1 7 9];
	:local months ("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec");
	:set date1month ([:find $months $date1month -1 ] + 1);
	:local daysAfterMonth ("31","59","90","120","151","181","212","243","273","304","334");
	:if ($date1month>1) do={:set $date1day ($date1day+[:pick $daysAfterMonth ($date1month-2)])};
	:set $date1year ($date1year-2020); :set $date1day ($date1day+$date1year*365+($date1year/4)); :set $date1hours ($date1hours+24*$date1day);
	:set $date1minutes ($date1minutes+60*$date1hours); :set $date1seconds ($date1seconds+(60*$date1minutes)-$myUTCoff);
	:local vTime ($date1seconds);
#   if the array is empty then initialise
	:if ((([:len $vDHCParray])=0) or ([:typeof ($vDHCParray)])!="array") do={ :set $vDHCParray ({}); };
#   insert the new Mac address in the global array    
	:local vPrevious; :set $vPrevious ($vDHCParray->$leaseActMAC);
	:local vMinDiff (($vTime-$vPrevious)/60);
#   if last seen more than 31 minutes ago then send the message    
	:if ($vMinDiff>31) do={
		if ($vMinDiff<(7*24*60)) do={
          :set $vTxtStr ($vHost . "=" . $leaseActIP . ": " . $vComment . " - previously before " . ($vMinDiff/60) . "h" . ($vMinDiff-(($vMinDiff)/60)*60) . "min")
        } else={ :set $vTxtStr ($vHost . "=" . $leaseActIP . ": " . $vComment . " - the first time") };
		$sendmessage ($vTxtStr);
	};
#	Update the global array (for the current MAC address) with the current time
	:if (([:len $vDHCParray])<128) do={:set ($vDHCParray -> $leaseActMAC) $vTime};
};
