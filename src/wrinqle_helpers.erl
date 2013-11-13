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

deliver_message(Channel,Msg) when not is_list(Channel)-> 
    Member = pg2:get_members(Channel),
    case Member of
	[Pid]-> Pid ! {jiffy:encode({[{status,200},{msg,Msg}]})};
	{error,_}->self()!{jiffy:encode({[{status,404}]})}
    end;

deliver_message(Channels,Msg) ->
    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      case Member of
		  [Pid] -> Pid ! {jiffy:encode({[{status,200},{msg,Msg}]})};
		  {error,_}->self()!{jiffy:encode({[{status,404}]})}
	      end
      end,Channels).


    
subscribe(To,Channel) when not is_list(To)->
    ok;
subscribe(To,Channels) ->ok.

publish(To,Msg)->
    ok.
