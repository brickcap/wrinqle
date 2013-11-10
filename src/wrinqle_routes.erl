-module(wrinqle_routes).
-export([routes_configuration/0]).

routes_configuration()->
    [{'_',[

	   {"/websocket",wrinqle_socket_handler,[]}
	  ]
     }
    ].
