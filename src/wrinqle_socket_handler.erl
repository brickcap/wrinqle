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

	 {[{<<"to">>,Channels},_]} when is_list(Channels)-> wrinqle_helpers:deliver_message(Channels,Msg);

	 {[{<<"to">>,Channel},_]}-> wrinqle_helpers:deliver_message(Channel,Msg);

	 {[{<<"register">>,Name}]}-> wrinqle_helpers:add_pid(self(),Name),
				     {reply, {text, jiffy:encode({[{registered,Name}]})}, Req, State};

	 _->{reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    catch
	{error,{no_such_group_name,_}}-> {reply,{text,jiffy:encode({[status,404]})}};
	_:_-> {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}
    after
	lager:info("Msg is~p",[Msg]),
	lager:info("Registered channels~p",[pg2:which_groups()])

    end;

websocket_handle(_Data, Req, State) ->  {ok, Req, State}. 

websocket_info({error,unavailaible},Req,State)->
    {reply,{text,jiffy:encode({[{status,404}]})},Req,State};

websocket_info({send,Msg},Req,State) ->
    {reply,{text,jiffy:encode({[{status,200},{msg,Msg}]})},Req,State};

websocket_info(subscribed,Req,State)->
    {reply,{text,jiffy:encode({[{status,200}]})},Req,State};

websocket_info({Channel,Msg},Req,State)->
    Member = pg2:get_members(self()),
    case list:member(Channel,Member) of
	true->   {reply,{text,jiffy:encode({[{from,Channel},{msg,Msg}]})},Req,State};
	false->
	    {ok,Req,State}
    end;


websocket_info(_Info, Req, State) ->
    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
    ok.

