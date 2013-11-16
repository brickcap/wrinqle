-module(wrinqle_event_handler).

-export([init/1]).
-export([handle_event/2]).

-behaviour(gen_event).

init(_Args)->
    {ok,[]}.
handle_event(send_message,To,Msg)-> 

    Member = pg2:get_members(To),


    case Member of
	[Pid|_] -> lager:info("Check ~p",Pid),
		   Pid!{send,Msg};
	{error,_}-> self()!{error,unavailable}
    end;
handle_event(send_message,To,Msg) when is_list(To) ->  

    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      case Member of

		  [Pid,_]->Pid!{send,Msg};
		  {error,_}-> self()!{error,unavailable}
	      end
      end,
      To);

handle_event(subscribe,To,Channel)->
    
    Member = pg2:get_members(To),
    case Member of
	[To|_]->pg2:join(Channel),
		self()!subscribed;
	{error,_} ->self()!error
    end;

handle_event(subscribe,To,Channels) when is_list(Channels) ->

    Member = pg2:get_members(To),
    case Member of
	[To|_]-> lists:foreach(fun(N)->pg2:join(N) end),
		 self()!subscribed;
	{error,_}-> self()!error
    end;

handle_event(publish,Channel,Msg)->

    Member = pg2:get_members(Channel),
    case Member of 
	[Channel|_]->Channel!{Channel,Msg};
	{error,_}-> failed
    end.


