-module(wrinqle_event_handler).

-export([init/1]).
-export([handle_event/2]).
-export([handle_call/2,terminate/2,handle_info/2,code_change/3]).

-behaviour(gen_event).

init(_Args)->
    {ok,[]}.

handle_event({send_message,To,Msg},State) when is_list(To) ->  

    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      case Member of

		  [Pid,_]->Pid!{send,Msg};
		  {error,_}-> self()!{error,unavailable}
	      end
      end,
      To),
	{ok,State};


handle_event({send_message,To,Msg},State)-> 

    Member = pg2:get_members(To),


    case Member of
	[Pid|_] -> lager:info("Check ~p",Pid),
		   Pid!{send,Msg};
	{error,_}-> self()!{error,unavailable}
    end,
	{ok,State};



handle_event({subscribe,To,Channels},State) when is_list(Channels) ->

    Member = pg2:get_members(To),
    case Member of
	[To|_]-> lists:foreach(fun(N)->pg2:join(N) end),
		 self()!subscribed;
	{error,_}-> self()!error
    end,
    {ok,State};


handle_event({subscribe,To,Channel},State)->

    Member = pg2:get_members(To),
    case Member of
	[To|_]->pg2:join(Channel),
		self()!subscribed;
	{error,_} ->self()!error
    end,
	{ok,State};

handle_event({publish,Channel,Msg},State)->

    Member = pg2:get_members(Channel),
    case Member of 
	[Channel|_]->Channel!{Channel,Msg};
	{error,_}-> failed
    end,
	{ok,State}.

handle_call(_, State) ->
    {ok, ok, State}.

handle_info(_, State) ->
    {ok, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
