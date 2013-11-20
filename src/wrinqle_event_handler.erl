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
		  [Pid|_]-> 
		     
		      Pid!{send,Msg};
		  {error,_}-> lager:info("Unavailable~p",N)
	      end
      end,
      To),
	{ok,State};


handle_event({send_message,To,Msg},State)-> 

    Member = pg2:get_members(To),


    case Member of
	[Pid|_] -> Pid!{send,Msg};
	{error,_}-> lager:info("unavailable:",Member)
    end,
	{ok,State};



handle_event({subscribe,To,Channels},State) when is_list(Channels) ->

    Member = pg2:get_members(To),
    case Member of
	[_|_]-> 
	    lists:foreach(
	      fun(N)->
		      Member_pids = pg2:get_members(N),
		      case Member_pids of
			  [Pid|_]->
			      pg2:join(Pid,To);
			  {error,_} -> lager:info("Unavailable")
		      end
	      end,Channels),
		 To!subscribed;
	{error,_}-> self()!error
    end,
    {ok,State};


handle_event({subscribe,To,Channel},State)->

    Member = pg2:get_members(To),
    case Member of
	[_|_]->

	    Member_Pids = pg2:get_members(Channel),
	    case Member_Pids of
		[Pid|_]->
		    pg2:join(Pid,To),
		    To!subscribed;

		{error,_}-> lager:info("Unavailable")
	    end;
	    {error,_} ->lager:info("Unavailable")
	      end,
    {ok,State};

handle_event({publish,Channel,Msg},State)->

    Member = pg2:get_members(Channel),
    case Member of 
	[Channel|_]->Channel!{send,Msg};
	{error,_}-> lager:info("unavailable")
    end,
    {ok,State};


handle_event({pid_registered,Pid},State) ->
    lager:info("Got Pid~p",pid),
    Pid! pid_registered,
    {ok,State};

handle_event({pid_unregistered,Pid},State) ->
    Pid!pid_unregistered,
    {ok,State};

handle_event(pid_unavailable,State) ->

    self()!pid_unavailable,
	{ok,State}.


handle_call(_, State) ->
    {ok, ok, State}.

handle_info(_, State) ->
    {ok, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
