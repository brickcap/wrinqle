-module(wrinqle_routes).
-exports([routes_configuration/0]).

routes_configuration()->
    [{'-',[

	   {"/websocket",wrinqle_socket_handler,[]}
	  ]
     }
    ].
