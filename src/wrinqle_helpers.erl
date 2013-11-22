-module(wrinqle_helpers).

-export([add_pid/2]).
-export([remove_pid/2]).
-export([channel_event_notifier/1]).

add_pid(Pid,Name)->

    Member = pg2:get_members(Name),

    case Member of

	{error,_} ->

	    pg2:create(Name),		   
	    pg2:join(Name,Pid),
	    channel_event_notifier({pid_registered,Pid}),
	    lager:info("The members of channel are",pg2:get_members(Name));
	
	_->  
	    ok

	     end.

remove_pid(Pid,Name)->

    Member = pg2:get_members(Name),

    case Member of

	{error,_} -> ok;
	_->
	    pg2:leave(Pid,Name)  
    end.

channel_event_notifier(Name)->
    Event_Pid = global:whereis_name(wrinqle_channel_events),   
    gen_event:notify(Event_Pid,Name).
