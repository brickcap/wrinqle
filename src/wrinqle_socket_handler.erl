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
    lager:info("pid~p",[self()]),
    try  jiffy:decode(Msg) of 

	 {[{<<"to">>,[H|T]},_]}-> wrinq_helpers:deliver_message([H|T],Msg);

	 {[{<<"to">>,Channel},_]}-> wrinq_helpers:deliver_message(Channel,Msg);

	 {[{<<"register">>,Name}]}-> wrinq_helpers:add_pid(self(),Name), 
				     {reply, {text, jiffy:encode({[{registered,Name}]})}, Req, State};

	 _->{reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    catch
	_:_-> {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    end;

websocket_handle(_Data, Req, State) ->  {ok, Req, State}. 


websocket_info({timeout, _Ref, Msg}, Req, State) ->
    erlang:start_timer(1000, self(), <<"How' you doin'?">>),
    {reply, {text, Msg}, Req, State};

websocket_info(_Info, Req, State) ->
    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
    ok.

