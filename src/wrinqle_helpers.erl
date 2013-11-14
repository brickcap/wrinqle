-module(wrinqle_helpers).

-export([add_pid/2]).
-export([deliver_message/2]).
-export([subscribe/2]).
-export([publish/2]).

add_pid(Pid,Name)->

    try Member = pg2:get_members(Name)

    catch 
	{error,_} ->pg2:create(Name),
		    pg2:join(Name,Pid)

    end.

deliver_message(To,Msg) when is_list(To),erlang:length(To)>0 ->
    lists:foreach( 
      fun(N)->
	      try Member = pg2:get_members(N),
		   [Pid,_] = Member,
		   Pid!{send,Msg}
	      catch
		  {error,{no_such_group_name,_}}-> self()!{error,unavailable},
						   deliver_message(element(2,lists:split(N,To)),Msg)
	      end
      end,
      To);


deliver_message(To,Msg)-> 
    Member = pg2:get_members(To),
    [Pid|_]= Member,
    Pid!{send,Msg}.
   


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
	[To|_]->pg2:join(Channel),
		self()!subscribed;
	{error,_} ->self()!error
    end.

publish(Channel,Msg)-> 
    Member = pg2:get_members(Channel),
    case Member of 
	[Channel|_]->Channel!{Channel,Msg};
	{error,_}-> failed
    end.

