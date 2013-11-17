-module(wrinqle_helpers).

-export([add_pid/2]).

add_pid(Pid,Name)->
    lager:info("The name of the channel is~p",[Name]),
    Member = pg2:get_members(Name),
    case Member of 
	{error,_} ->pg2:create(Name),		   
		    pg2:join(Name,Pid),
		     lager:info("The members of channel are",pg2:get_members(Name));
	_->  ok
end.

