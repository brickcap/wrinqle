-module(wrinqle_event_handler).

-export([init/1]).
-export([handle_event/2]).
-export([handle_call/2,terminate/2,handle_info/2,code_change/3]).

-behaviour(gen_event).

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
    pg2:create(Subscriber_Channel),
    [M|_] = pg2:get_members(Multi_Subscribe_To),
    case M of 
	{error,_}->ok;
	_->
  	    lists:foreach(
	      fun(N)->
		      Member_pids = pg2:get_members(N),
		      case Member_pids of
			  [Pid|_]->
			      pg2:join(Subscriber_Channel,Pid),
			      Pid! subscribed;
			  {error,_} -> lager:info("Unavailable")
		      end
	      end,Subscribers)
    end,
    M!{send,{[{<<"subcribed">>,<<"ok">>}]}},
{ok,State};


handle_event({publish,Publish_Msg,Publishing_Channel},State)->

    Member = pg2:get_members(wrinqle_helpers:subscriber_channel_name(Publishing_Channel)),
    case Member of 
	[M|O]->
	    [Pid!{send,Publish_Msg}||Pid<-[M|O]];
	{error,_}-> lager:info("unavailable")
    end,
    {ok,State};


handle_event({pid_registered,Pid},State) ->
    lager:info("Got Pid~p",pid),
    Pid! pid_registered,
    {ok,State}.

handle_call(_, State) ->
    {ok, ok, State}.

handle_info(_, State) ->
    {ok, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
