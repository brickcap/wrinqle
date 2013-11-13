-module(wrinqle_helpers).

-export([add_pid/2]).
-export([deliver_message/2]).
-export([subscribe/2]).

add_pid(Pid,Name)->
Member = pg2:get_members(Name),
    case Member of
	[Pid|_]-> ok;
	{error,_} ->pg2:create(Name),
		    pg2:join(Name,Pid)
    end.

deliver_message(To,Msg) when is_list(To) ->
    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      case Member of
		  [Pid|_] -> Pid ! {send,Msg};
		  {error,_}->self()!{error,un_availaible}
	      end
      end,To);


deliver_message(To,Msg)-> 
    Member = pg2:get_members(To),
    case Member of
	[Pid]-> Pid ! {send,Msg};
	{error,_}->self()!{error,un_available}
    end.



subscribe(To,Channels) when  is_list(Channels)-> 
    Member = pg2:get_members(To),
    case Member of
	[To|_]-> lists:foreach(fun(N)->pg2:join(N) end),
		 self()!subscribed;
	{error,_}-> self()!error
    end;
subscribe(To,Channel) ->
    Member = pg2:get_members(To),
    case Member of
	[To|_]->pg2:join(N),
		self()!subscribed;
	{error,_} ->self()!error
    end.

publish(To,Msg)->
    ok.
