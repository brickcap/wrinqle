-module(wrinqle_socket_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

init({tcp, http}, _Req,_Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
    {ok, Req, undefined_state}.


websocket_handle({text, Msg}, Req, State) ->

   
    try  jiffy:decode(Msg) of 


	 {[{<<"register">>,Register_Name}]}->

	    wrinqle_helpers:channel_event_notifier({register_pid,self(),Register_Name}),
	    {ok,Req,Register_Name};


	 {[{<<"to">>,Multi_Channels},{<<"msg">>,Multi_Message}]} when is_list(Multi_Channels)->

	    True_Channels = lists:delete(State,Multi_Channels),
	    lager:info("The true channels are",[True_Channels]),
	    wrinqle_helpers:channel_event_notifier({send_message,True_Channels,Multi_Message}),

	    {ok,Req,State};



	 {[{<<"subscribe">>,Subscribe_Channels},{<<"to">>,To}]}-> 

	    True_Channels = lists:delete(State,Subscribe_Channels),
	    wrinqle_helpers:channel_event_notifier({subscribe,To,True_Channels}),
	    {ok,Req,State};

	 {[{<<"publish">>,Publish_Msg},{<<"to">>,Pub_Channel}]}->

	    wrinqle_helpers: channel_event_notifier({publish,Publish_Msg,Pub_Channel}),
	    {ok,Req,State};

	 _->

	    {reply, {text, jiffy:encode({[{error,<<"invalid packet">>}]})}, Req, State}

    catch
	_:_-> {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    end;

websocket_handle(_Data, Req, State) ->  {ok, Req, State}. 


websocket_info({send,Socket_Send_Msg},Req,State) ->

    {reply,{text,jiffy:encode({[{status,200},{msg,Socket_Send_Msg}]})},Req,State};


websocket_info(subscribed,Req,State)->

    {reply,{text,jiffy:encode({[{status,200}]})},Req,State};

websocket_info(pid_registered,Req,State)->
    
    {reply,{text,<<"OK">>},Req,State};

websocket_info(_Info, Req, State) ->

    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->

    pg2:delete(_State),
    pg2:delete(wrinqle_helpers:subscriber_channel_name(_State)),
    ok.

