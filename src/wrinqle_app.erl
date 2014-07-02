-module(wrinqle_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).



start(_Type, _Args) ->

	Dispatch = cowboy_router:compile(wrinqle_routes:routes_configuration()),
	{ok, _} = cowboy:start_http(http, 100, [{port, 4000}],
				    [{env, [{dispatch, Dispatch}]}]),
    pg2:start(),

    gen_event:start({global,wrinqle_channel_events}),
    gen_event:add_handler({global,wrinqle_channel_events},wrinqle_event_handler,[]),

    wrinqle_sup:start_link().

stop(_State) ->
	ok.


