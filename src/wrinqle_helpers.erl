-module(wrinqle_helpers).

-export([add_pid/2]).

add_pid(Pid,Name)->
    
    Member = pg2:get_members(Name),

    case Member of
 
	{error,_} ->

	    pg2:create(Name),		   
	    pg2:join(Name,Pid),
	    lager:info("The members of channel are",pg2:get_members(Name));

	_->  ok

    end.

remove_pid(Pid,Name)->

    Member = pg2:get_members(Name),

    case Member of

	{error,_} ->ok;

	_->

	    pg2:leave(Pid,Name)  
    end.
