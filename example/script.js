var sockets=[];
var info = document.getElementById("socketInfo");
for(var i=0;i<=100;i++){
   console.log(i.toString()); 
    sockets.push(new WebSocket("ws://localhost:4000/websocket/socket"+i.toString()));
    sockets[i].onopen = function(){
	if(i>4){
	    sockets[0].send(JSON.stringify({"to":["socket3","socket4"],"msg":"Hey there"}));
	}
    };
    sockets[i].onmessage = function(data){
	info.innerHTML+="<li>"+i.toString()+": "+data.data+"</li>";
    };


}



