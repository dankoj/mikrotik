#Telegram botID from https://t.me/botfather chatID from https://t.me/get_id_bot
#Parse function with: :global sendmessage [:parse [/system script get send_message source]];
{
  :local botID "bot1234567890:ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
  :local chatID "123456789";
#  global aMessages has to be declared and refreshed in a router startup script
  :global aMessages; :local vHasErrors ""; local sMessageText;
    if ($1 != "" ) do={
    do { /tool fetch url="https://api.telegram.org/$botID/sendMessage\?chat_id=$chatID&text=$1" keep-result=no;
       :log info ("Telegram sent: " . ($1));
       } on-error={ if (([:len ([:tostr ($aMessages)])]) < 3500) do={
#                      if send fails (no Internet) add current message in the $aMessages array           
                       set $aMessages ($aMessages, $1);
                       :log info ("Telegram FAILED #$[:len $aMessages]: " . ($1)); 
                    } else={:log info ("Telegram FAILED #$[:len $aMessages]: to long: " . ([:len ([:tostr ($aMessages)])]) ) }
		  }
  }
# if any old (unsent) messages try to resend them  
  if (([:len $aMessages])>0) do={
    :log info ("Telegram resending: $[:len $aMessages] messages: $[:tostr $aMessages]");
    :set $sMessageText ("Resending $[:len $aMessages] messages from $[/system identity get name]:");
    /tool fetch url="https://api.telegram.org/$botID/sendMessage\?chat_id=$chatID&text=$sMessageText" keep-result=no;
    :foreach i in $aMessages do={
      :set $sMessageText ([:tostr ($i)]);
      do { 
         if (([:len $sMessageText])>0) do={
           /tool fetch url="https://api.telegram.org/$botID/sendMessage\?chat_id=$chatID&text=$sMessageText" keep-result=no;
         }
      } on-error={:set $vHasErrors ($sMessageText) };
    }
    :if ($vHasErrors="") do={
        :log info "Telegram resend success";
        :set $aMessages ({}) 
    } else={:log info ("Telegram resend fail ($[:typeof $sMessageText] - $[:len $sMessageText]): " . $sMessageText);}
  }
}