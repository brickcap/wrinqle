-module(wrinqle_helpers).
-export([add_pid/2]).

add_pid(Pid,Name)->
Member = pg2:get_members(Name),
    case Member of
	[Pid]-> ok;
	{error,_} ->pg2:create(Name),
		    pg2:join(Name,Pid)
    end.
