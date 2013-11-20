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

	 {[{<<"to">>,Channels},{<<"msg">>,Message}]} when is_list(Channels)->
	    
	    wrinqle_helpers:channel_event_notifier({send_message,Channels,Message}),

	    {ok,Req,State};

	 {[{<<"to">>,Channel},{<<"msg">>,Message}]}->

	    wrinqle_helpers:channel_event_notifier({send_message,Channel,Message}),

	    {ok,Req,State};

	 {[{<<"register">>,Name}]}->
	    lager:info("registered processes ~p",global: registered_names()),
	    wrinqle_helpers: add_pid(self(),Name),
	    {ok,Req,State};

	 {[{<<"subscribe">>,Channels},{_,To}]}-> 
	    erlang:display("In subscribe"),

	    wrinqle_helpers:channel_event_notifier({subscribe,To,Channels}),
	    {ok,Req,State};

	 {[{<<"publish">>,Msg},{_,Channel}]}->
	    wrinqle_helpers: channel_event_notifier({publish,Channel,Msg}),
	    {ok,Req,State};
	 _->
	    {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

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

