-module(wrinqle_event_handler).

-export([init/1]).
-export([handle_event/2]).
-export([handle_call/2,terminate/2,handle_info/2,code_change/3]).

-behaviour(gen_event).

-include("wrinqle.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.


init(_Args)->
    {ok,[]}.

handle_event({send_message,Multi_Channels,Multi_Msg},State) when is_list(Multi_Channels) ->  

    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      lager:info("Sending message to",[{N, Member}]),
	      case Member of
		  [Pid|_]-> 

		      Pid!{send,Multi_Msg};
		  {error,_}-> lager:info("Unavailable~p",N)
	      end
      end,
      Multi_Channels),
    {ok,State};


handle_event({subscribe,Multi_Subscribe_To,Subscribers},State) when is_list(Subscribers) ->

    Subscriber_Channel = wrinqle_helpers:subscriber_channel_name(Multi_Subscribe_To), 
    Member = pg2:get_members(Subscriber_Channel), 
    case Member of 
	{error,_}->
	    pg2:create(Subscriber_Channel),
	    wrinqle_helpers:add_subscribers(Subscriber_Channel,Subscribers);
	_->
	    wrinqle_helpers:add_subscribers(Subscriber_Channel,Subscribers) 
    end,
    [G|_]= pg2:get_members(Multi_Subscribe_To),
    G ! subscribed,
    {ok,State};


handle_event({publish,Publish_Msg,Publishing_Channel},State)->

    Member = pg2:get_members(wrinqle_helpers:subscriber_channel_name(Publishing_Channel)),
    case Member of 
	[M|O]->
	    [Pid!{send,Publish_Msg}||Pid<-[M|O]];
	{error,_}-> lager:info("unavailable")
    end,
    {ok,State};


handle_event({register_pid,Pid,Name},State) ->

    lager:info("Got Pid~p",pid),
    pg2:create(Name),		   
    pg2:join(Name,Pid),
    lager:info("The members of channel are",[Name,pg2:get_members(Name)]),
    Pid! {pid_registered,Name},
    {ok,State}.

handle_call(_, State) ->
    {ok, ok, State}.

handle_info(_, State) ->
    {ok, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.


-ifdef(TEST).


    
register_pid_test()->
    Result = handle_event({register_pid,self(),test_pid},some_state),
    receive
	{pid_registered,Name}->
	    ?assertEqual(Result,{ok,some_state}),
	    pg2:delete(test_pid)    
    end.

send_message_test()->
    List =  [<<"one">>,<<"two">>,<<"three">>],
    Msg = <<"Hello there">>,
    lists:foreach(
      fun(N)->
	      pg2:create(N),
	      pg2:join(N,self())
      end,List),
    Result = handle_event({send_message,List,Msg},some_state),
    receive
	{send,S_Msg}->
	    ?assertEqual(Result,{ok,some_state})
    end.


-endif.
