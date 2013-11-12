-module(wrinqle_helpers).

-export([add_pid/2]).
-export([deliver_message/2]).

add_pid(Pid,Name)->
Member = pg2:get_members(Name),
    case Member of
	[Pid]-> ok;
	{error,_} ->pg2:create(Name),
		    pg2:join(Name,Pid)
    end.

deliver_message(Channel,Msg)-> 
    Member = pg2:get_members(Channel),
    case Member of
	[Pid]-> Pid ! {jiffy:encode({[{status,200}]})};
	{error,_}->{jiffy:encode({[{status,404}]})}
    end;
 
deliver_message(Channels,Msg) ->ok.

