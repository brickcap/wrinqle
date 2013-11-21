-module(wrinqle_socket_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

init({tcp, http}, _Req, _Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
       {ok, Req, undefined_state}.


websocket_handle({text, Msg}, Req, State) ->

    %%lager:info("Got message ~p",[Msg]),
    try  jiffy:decode(Msg) of 

	 {[{<<"to">>,Multi_Channels},{<<"msg">>,Multi_Message}]} when is_list(Multi_Channels)->
	    
	    wrinqle_helpers:channel_event_notifier({send_message,Multi_Channels,Multi_Message}),

	    {ok,Req,State};

	 {[{<<"to">>,Single_Channel},{<<"msg">>,Single_Message}]}->

	    wrinqle_helpers:channel_event_notifier({send_message,Single_Channel,Single_Message}),

	    {ok,Req,State};

	 {[{<<"register">>,Register_Name}]}->
	    lager:info("registered processes ~p",global: registered_names()),
	    wrinqle_helpers: add_pid(self(),Register_Name),
	    {ok,Req,State};

	 {[{<<"subscribe">>,Subscribe_Channels},{<<"to">>,To}]}-> 
	    erlang:display("In subscribe"),

	    wrinqle_helpers:channel_event_notifier({subscribe,To,Subscribe_Channels}),
	    {ok,Req,State};

	 {[{<<"publish">>,Publish_Msg},{<<"to">>,Pub_Channel}]}->
	    erlang:display("Triggering Publish"),
	    wrinqle_helpers: channel_event_notifier({publish,Publish_Msg,Pub_Channel}),
	    {ok,Req,State};

	 _->
	   
	    {reply, {text, jiffy:encode({[{error,<<"invalid packet">>}]})}, Req, State}

    catch
	_:_-> {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    end;

websocket_handle(_Data, Req, State) ->  {ok, Req, State}. 


websocket_info({send,Msg},Req,State) ->
    lager:info("Send recieved~p",{send,Msg}),
    {reply,{text,jiffy:encode({[{status,200},{msg,Msg}]})},Req,State};


websocket_info({Channel,Msg},Req,State)->
    Member = pg2:get_members(self()),
    case list:member(Channel,Member) of
	true->  
	    {reply,{text,jiffy:encode({[{from,Channel},{msg,Msg}]})},Req,State};
	false->
	    {ok,Req,State}
    end;

websocket_info(subscribed,Req,State)->
    {reply,{text,jiffy:encode({[{status,200}]})},Req,State};

websocket_info(pid_registered,Req,State)->
    lager:info("Caught ~p"),
    {reply,{text,<<"OK">>},Req,State};

websocket_info(_Info, Req, State) ->
    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
    ok.

