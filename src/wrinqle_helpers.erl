-module(wrinqle_helpers).

-export([add_pid/2]).
-export([remove_pid/2]).

add_pid(Pid,Name)->
    
    Member = pg2:get_members(Name),

    case Member of
 
	{error,_} ->

	    pg2:create(Name),		   
	    pg2:join(Name,Pid),
	    gen_event:notify(wrinqle_channel_events,pid_registered),
	    lager:info("The members of channel are",pg2:get_members(Name));

	_->  
	    gen_event:notify(wrinqle_channel_events,channel_unavailable)

    end.

remove_pid(Pid,Name)->

    Member = pg2:get_members(Name),

    case Member of

	{error,_} -> gen_event:notify(wrinqle_channel_events,channel_unavailable);
 

	_->

	    pg2:leave(Pid,Name),  
	    gen_event:notify(wrinqle_channel_events,pid_removed)

    end.
