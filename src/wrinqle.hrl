%constants
-define(to,<<"to">>).
-define(msg,<<"msg">>).
-define(sub,<<"subscribe">>).
-define(pub,<<"publish">>).

%%functions
-define(error_packet,jiffy:encode({[{error,<<"invalid packet">>}]})).
-define(error_json,jiffy:encode({[{error,<<"invalid json">>}]})).
-define(send_msg(Socket_Send_Msg),jiffy:encode({[{status,200},{msg,Socket_Send_Msg}]})).
-define(status_ok,jiffy:encode({[{status,200}]})).
