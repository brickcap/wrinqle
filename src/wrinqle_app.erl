%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(wrinqle_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.
start(_Type, _Args) ->
	Dispatch = cowboy_router:compile(wrinqle_routes:routes_configuration()),
	{ok, _} = cowboy:start_http(http, 100, [{port, 3000}],
				    [{env, [{dispatch, Dispatch}]}]),
    pg2:start(),

    gen_event:start({global,channel_events}),
    gen_event:add_handler({global,channel_events},wrinqle_event_handler,[]),

    wrinqle_sup:start_link().

stop(_State) ->
	ok.
