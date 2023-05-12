:delay 10;
:log info "Router Startup script";
#Startup logic moved to Startup_Script (Changes in 2023 for compatibility with RouterOS 7.x)
#To retain global variable value it has to be defined in startup (re-checked with Check_Status script)
:global vDHCParray;:global aMessages;
:global templaststatus "system temp is within spec";
:global nLastUsers ([user print count-only as-value]);
:global WANinterface "";
:global currentWANIP "";
:global currentIP "";
:global sFirewalls "";
:global aIfaceS "";
:global sIntInterface "";
:delay 30;
#
#Parse function to send message to Telegram app
:global sendmessage [:parse [/system script get send_message source]];
#
:system script run Startup_Script;
:delay 60;
:system script run Backup;
#
#To retain global variable value statup has to continue running indefinitely 
:while (1) do={:delay 60;};
:log info "Router Startup script ENDS (but it should never end)";
