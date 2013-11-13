-module(wrinqle_helpers).

-export([add_pid/2]).
-export([deliver_message/2]).
-export([subscribe/2]).

add_pid(Pid,Name)->
Member = pg2:get_members(Name),
    case Member of
	[Pid]-> ok;
	{error,_} ->pg2:create(Name),
		    pg2:join(Name,Pid)
    end.

deliver_message(To,Msg) when is_list(To) ->
    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      case Member of
		  [Pid] -> Pid ! {jiffy:encode({[{status,200},{msg,Msg}]})};
		  {error,_}->self()!{jiffy:encode({[{status,404}]})}
	      end
      end,To);


deliver_message(To,Msg)-> 
    Member = pg2:get_members(To),
    case Member of
	[Pid]-> Pid ! {jiffy:encode({[{status,200},{msg,Msg}]})};
	{error,_}->self()!{jiffy:encode({[{status,404}]})}
    end.


    
subscribe(To,Channel) when  is_list(Channel)-> 
    ok;
subscribe(To,Channel) ->ok.

publish(To,Msg)->
    ok.
