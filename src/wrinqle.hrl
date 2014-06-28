-define(multi_message(Channels,Message),[{<<"to">>,Channels},{<<"msg">>,Message}]).
-define(subscribe(Channels,To),[{<<"subscribe">>,Channels},{<<"to">>,To}]).
-define(publish(Message,Channel_Name),[{<<"publish">>,Message},{<<"to">>,Channel_Name}]).

