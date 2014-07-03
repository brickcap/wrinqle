-module(wrinqle_socket_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

-include("wrinqle.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.


init({tcp, http}, _Req,_Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
    {Channel_Name,Req2} = cowboy_req:binding(channel_name,Req),
    wrinqle_helpers:channel_event_notifier({register_pid,self(),Channel_Name}),
    {ok, Req2, Channel_Name}.


websocket_handle({text, Msg}, Req, State) ->

   
    try  jiffy:decode(Msg) of 


	 {[{?to,[H|T]},{?msg,Multi_Message}]}->

	    True_Channels = lists:delete(State,[H|T]),
	    lager:info("The true channels are",[True_Channels]),
	    wrinqle_helpers:channel_event_notifier({send_message,True_Channels,Multi_Message}),

	    {ok,Req,State};



	 {[{?sub,[H|T]},{?to,To}]}-> 

	    True_Channels = lists:delete(State,[H|T]),
	    wrinqle_helpers:channel_event_notifier({subscribe,To,True_Channels}),
	    {ok,Req,State};

	 {[{?pub,Publish_Msg},{?to,Pub_Channel}]}->

	    wrinqle_helpers: channel_event_notifier({publish,Publish_Msg,Pub_Channel}),
	    {ok,Req,State};

	 _->

	    {reply, {text, ?error_packet}, Req, State}

    catch
	_:_-> {reply, {text, ?error_json}, Req, State}

    end;

websocket_handle(_Data, Req, State) ->  {ok, Req, State}. 


websocket_info({send,Socket_Send_Msg},Req,State) ->

    {reply,{text,?send_msg(Socket_Send_Msg)},Req,State};


websocket_info(subscribed,Req,State)->

    {reply,{text,?status_ok},Req,State};

websocket_info({pid_registered,_Name},Req,State)->
    
    {reply,{text,?status_ok},Req,State};

websocket_info(_Info, Req, State) ->

    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
lager:info(_State),
 case _State of
	undefined_state->ok;
	_->
	    pg2:delete(_State),
	    pg2:delete(wrinqle_helpers:subscriber_channel_name(_State)),
	    ok
    end.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

handle_msg_test_()->
{setup,fun start/0,fun stop/1,fun test_text_msg/0}.
    
start()->
    {ok,Pid}= gen_event:start({global,wrinqle_channel_events}),
    gen_event:add_handler({global,wrinqle_channel_events},wrinqle_event_handler,[]),
    Pid.

test_text_msg()->
    Result1 = websocket_handle({text,<<"{\"to\":[\"hello\"],\"msg\":\"Hey Joe\"}">>},req,to_state),
    Result2 = websocket_handle({text,<<"{\"subscribe\":[\"hello\"],\"to\":\"me\"}">>},req,sub_state),
    Result3 = websocket_handle({text,<<"{\"publish\":\"hello\",\"to\":\"me\"}">>},req,pub_state),
    Result4 = websocket_handle({text,<<"{\"dancingqueen\":\"true\"}">>},req,err_state),
    ?assertEqual(Result1,{ok,req,to_state}),
    ?assertEqual(Result2,{ok,req,sub_state}),
    ?assertEqual(Result3,{ok,req,pub_state}),
    ?assertEqual(Result4,{reply, {text,?error_packet}, req, err_state}).

subscribed_test()->        
    Result = websocket_info(subscribed,req,state),
    ?assertEqual(Result,{reply,{text,?status_ok},req,state}).

registered_test()->    
    Result = websocket_info(subscribed,req,state),
    ?assertEqual(Result,{reply,{text,?status_ok},req,state}).

send_test()->    
    Result = websocket_info({send,<<"Message">>},req,state),
    ?assertEqual(Result, {reply,{text,?send_msg(<<"Message">>)},req,state}).  

stop(Pid)->
    ok.
-endif.
