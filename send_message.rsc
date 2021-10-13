#Telegram botID from https://t.me/botfather chatID from https://t.me/get_id_bot
#Parse function with: :global sendmessage [:parse [/system script get send_message source]];
{
  :global UrlEncode;
  :set UrlEncode do={
    :local Input [ :tostr $1 ];
    :if ([ :len $Input ] = 0) do={ :return ""; }
    :local Return "";
    :local Chars ("\n\r !\"#\$%&'()*+,:;<=>\?@[\\]^`{|}~šðèæžŠÐÈÆŽ");
    :local Subs { "%0A"; "%0D"; "%20"; "%21"; "%22"; "%23"; "%24"; "%25"; "%26"; "%27";
          "%28"; "%29"; "%2A"; "%2B"; "%2C"; "%3A"; "%3B"; "%3C"; "%3D"; "%3E"; "%3F";
          "%40"; "%5B"; "%5C"; "%5D"; "%5E"; "%60"; "%7B"; "%7C"; "%7D"; "%7E";
          "%C5%A1"; "%C4%91"; "%C4%8D"; "%C4%87"; "%C5%BE"; "%C5%A0"; "%C4%90"; "%C4%8C"; "%C4%86"; "%C5%BD" };
    :for I from=0 to=([ :len $Input ] - 1) do={
      :local Char [ :pick $Input $I ];
      :local Replace [ :find $Chars $Char ];
      :if ([ :typeof $Replace ] = "num") do={ :set Char ($Subs->$Replace); }
      :set Return ($Return . $Char); }
    :return $Return; }
  
    :local botID "bot1234567890:ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    :local chatID "123456789";	

#   global aMessages has to be declared and refreshed in a router startup script	
    :global aMessages; :local vHasErrors ""; :local sMessageText;
    :set $sMessageText ([:tostr ($1)]);
#    :log info $sMessageText;
    :set $sMessageText [ $UrlEncode $sMessageText ];
    if ($sMessageText != "" ) do={
      do { /tool fetch url="https://api.telegram.org/$botID/sendMessage?chat_id=$chatID&parse_mode=HTML&text=$sMessageText"  output=none;
         :log info ("Telegram sent: " . $sMessageText);
         } on-error={ if (([:len ([:tostr ($aMessages)])]) < 3500) do={
#                        if send fails (no Internet) add current message in the $aMessages array  			              
                         set $aMessages ($aMessages, $sMessageText);
                         :log info ("Telegram FAILED #$[:len $aMessages]: " . $sMessageText); 
                      } else={:log info ("Telegram FAILED #$[:len $aMessages]: to long: " . ([:len ([:tostr ($aMessages)])]) ) }
        }
    }
#   if any old (unsent) messages try to resend them  	    
    if (([:len $aMessages])>0) do={
      :log info ("Telegram resending: $[:len $aMessages] messages: $[:tostr $aMessages]");
      :set $sMessageText ("Resending $[:len $aMessages] messages from $[/system identity get name]:");
      :delay 2;
      /tool fetch url="https://api.telegram.org/$botID/sendMessage?chat_id=$chatID&parse_mode=HTML&text=$sMessageText"  output=none;
      :foreach i in $aMessages do={
        :set $sMessageText ([:tostr ($i)]);
        :log info ("resending text: $[:tostr $sMessageText]");
        :delay 1;
        do { 
           if (([:len $sMessageText])>0) do={
             /tool fetch url="https://api.telegram.org/$botID/sendMessage?chat_id=$chatID&parse_mode=HTML&text=$sMessageText"  output=none;
           }
        } on-error={:set $vHasErrors ($sMessageText) };
      }
      :if ($vHasErrors="") do={
          :log info "Telegram resend success";
          :set $aMessages ({}) 
      } else={:log info ("Telegram resend fail ($[:typeof $sMessageText] len: $[:len $sMessageText]): " . $sMessageText);}
    }
  }
