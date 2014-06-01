
var socket = new WebSocket("ws://localhost:4000/websocket/test");

socket.onopen = function(){
    console.log("socket has been opened");
};
socket.onmessage = function(data){
    console.log(data);
};

window.onbeforeunload = function(){
socket.disconnect();
};
