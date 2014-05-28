var socket = new Socket("ws://localhost:4000/test");

socket.onopen = function(){
    console.log("socket has been opened");
};
